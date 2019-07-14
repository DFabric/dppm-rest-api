module DppmRestApi::Actions::Groups
  class NoSuchGroup < NotFound
    def initialize(context : HTTP::Server::Context, id : String, cause : Exception? = nil)
      super context, "No group found with ID " + id, cause
    end
  end

  class InvalidAccessLevel < BadRequest
    def initialize(context : HTTP::Server::Context, cause : Exception? = nil)
      level = context.params.url["access_level"]? || context.params.query["access_level"]?
      super context, %[Given access level "#{level}" is not valid], cause
    end
  end

  def query_params_in_body?(of context : HTTP::Server::Context) : Hash(String, Array(String))
    if body = context.request.body
      Hash(String, Array(String)).from_json body
    else
      Hash(String, Array(String)).new
    end
  rescue e : JSON::ParseException
    raise BadRequest.new context, <<-HERE, cause: e
      Expected either a valid JSON Hash of String to Array of String, or no
      specified request body at #{context.request.path}
      HERE
  end

  extend self
  include RouteHelpers
  relative_post do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Create
    body = context.request.body
    raise BadRequest.new context, "One must specify a group to add." if body.nil?
    group = Config::Group.from_json body
    DppmRestApi.permissions_config.groups << group
    DppmRestApi.permissions_config.sync_to_disk
    build_json context.response do |response|
      response.field("successfullyAddedGroup") { group.to_json response }
    end
  end
  # Regardless of whether the given path exists on the given group, set the
  # group's access level on that path to the given access level.
  relative_put "/:id/route/:path/:access_level" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    group_id_s = context.params.url["id"]
    group_id = group_id_s.to_i? || raise BadRequest.new context,
      %[Group ID #{group_id_s} was not a valid integer]
    # find the group if it already exists in the permissions config
    index = DppmRestApi.permissions_config
      .groups
      .index { |grp| grp.id == group_id }
    raise NoSuchGroup.new context, group_id_s if index.nil?
    old_group = DppmRestApi.permissions_config.groups[index]
    path = URI.unescape context.params.url["path"]
    access_level = Access.parse?(context.params.url["access_level"])
    raise InvalidAccessLevel.new context if access_level.nil?
    name = context.params
      .query["name"]?
      .try { |param| URI.unescape param } || old_group.name
    # Create the group if it doesn't already exist
    group = Config::Group.new id: group_id, name: name,
      permissions: old_group.permissions
    # Create a query parameters object (since the default isn't nil, it's an
    # empty Hash) if group doesn't already have a path with query params on
    # it.
    existing_params = group.permissions[path]?
      .try &.query_parameters || {} of String => Array(String)
    # if there were query parameters specified in the body, override
    # existing values
    existing_params.merge! query_params_in_body?(of: context) do |_path, existing, new_val|
      existing + new_val
    end
    # Override the existing permissions
    group.permissions[path] = Config::Route.new access_level, existing_params
    # and overwrite the current value.
    DppmRestApi.permissions_config.groups[index] = group
    build_json context.response do |response|
      response.field "successfullyModifiedGroup" do
        response.object do
          response.field("from") { old_group.to_json response }
          response.field("to") { group.to_json response }
        end
      end
    end
  end
  # Remove specific query parameters from this path/access-level for this
  # group. The query parameters may be specified via query parameters like:
  # ```
  # ?some-param=value&some-param=value2
  # ```
  # Not specifying any query parameters will delete all parameter
  # specifications on this route.
  #
  # Not specifying a list of values...
  # ```
  # ?some-param&some-other-param
  # ```
  # ...will delete that parameter from the group.
  #
  # So, in summary the request...
  # ```
  # /123/param/%2Fsome%2Fpath?some-param=value&param2&param3&param4=value2&param4=value3
  # ```
  # ...(if succesful) would result in the deletion of the following query
  # parameter permissions on `/some/path` for group `123`:
  #  - access to "value" on the query parameter  "some-param"
  #  - access to any route which requires `param2` or `param3` to be specified
  #  - access to "value2" and "value3" on "param4"
  relative_delete "/:id/param/:path" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    path = context.params.url["path"]
    group_id_s = context.params.url["id"]
    group_id = group_id_s.to_i? || raise BadRequest.new context,
      %[Group ID "#{group_id_s}" was not an integer!]
    group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == group_id }
    raise NoSuchGroup.new context, group_id_s if group_idx.nil?
    group = DppmRestApi.permissions_config.groups[group_idx]
    route = group.permissions[path]? || raise NotFound.new context,
      "No permissions settings found for group #{group.id} (#{group.name}) \
        on the path glob #{path}."
    next route.query_parameters.clear if context.request.query_params.empty?
    route.query_parameters.each do |key, values|
      next unless route.query_parameters.has_key? key
      specified = context.request.query_params.fetch_all key
      if specified.empty?
        route.query_parameters.delete key
      else
        pp!(values, specified, (route.query_parameters[key] = values - specified))
      end
    end
    build_json context.response do |json|
      json.field "status", "success"
    end
  end

  relative_delete "/:id/route/:path" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    group_id = (group_id_s = context.params.url["id"]).to_i?
    raise BadRequest.new context,
      %[Group ID "#{group_id_s}" was not an integer] if group_id.nil?
    group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == group_id }
    raise NoSuchGroup.new context, group_id_s if group_idx.nil?
    group = DppmRestApi.permissions_config.groups[group_idx]
    deleted = group.permissions.delete context.params.url["path"]
    raise NotFound.new context,
      "no permissions found at the specified path (possibly already \
        deleted?)" if deleted.nil?
    DppmRestApi.permissions_config.sync_to_disk
    build_json context.response do |response|
      response.field ("deleted") { deleted.to_json response }
    end
  end

  relative_delete "/:id" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    group_id = (group_id_s = context.params.url["id"]).to_i?
    raise BadRequest.new context,
      %[Group ID "#{group_id_s}" was not an integer] if group_id.nil?
    to_be_deleted = DppmRestApi.permissions_config
      .groups
      .index { |group| group.id == group_id }
    raise NoSuchGroup.new context, group_id_s if to_be_deleted.nil?
    group = DppmRestApi.permissions_config.groups[to_be_deleted]
    DppmRestApi.permissions_config.groups.delete_at to_be_deleted
    DppmRestApi.permissions_config.sync_to_disk
    build_json context.response do |response|
      response.field("successfullyDeletedGroup") { group.to_json response }
    end
  end
end
