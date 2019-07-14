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

  struct QueryDeleteRequest
    class NullAssertionFailed < Exception
      def initialize
        super message: "Someone forgot to check if queryParameters was null \
          before iterating through it!"
      end
    end

    include JSON::Serializable
    # ameba:disable Style/VariableNames
    private getter queryParameters : Hash(String, Array(String)?) do
      raise NullAssertionFailed.new
    end

    def all?
      # ameba:disable Style/VariableNames
      @queryParameters.nil?
    end

    def each
      queryParameters.each { |k, v| yield k, v }
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
    if Actions.has_access? context, Access::Create
      body = context.request.body
      raise BadRequest.new context, "One must specify a group to add." if body.nil?
      group = Config::Group.from_json body
      DppmRestApi.permissions_config.groups << group
      DppmRestApi.permissions_config.sync_to_disk
      build_json context.response do |response|
        response.field("successfullyAddedGroup") { group.to_json response }
      end
      next context
    end
    raise Unauthorized.new context
  end
  # Regardless of whether the given path exists on the given group, set the
  # group's access level on that path to the given access level.
  relative_put "/:id/route/:path/:access_level" do |context|
    if Actions.has_access? context, Access::Update
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
      next context
    end
  end
  # Remove specific query parameters from this path/access-level for this
  # group. The query parameters must be specified in a JSON body like:
  # ```json
  # { "queryParameters": {"some-param": ["value"]}}
  # ```
  # Specifying null instead of the queryParameters object...
  # ```json
  # { "queryParameters": null }
  # ```
  # ...will delete all parameter specifications on this route. Specifying
  # null instead of a list of values...
  # ```json
  # { "queryParameters": { "some-param": null } }
  # ```
  # ...will delete that parameter from the group.
  relative_delete "/:id/param/:path" do |context|
    if Actions.has_access? context, Access::Update
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
      body = context.request.body || raise BadRequest.new context,
        "a JSON body must be specified at this endpoint"
      deletion_requests = QueryDeleteRequest.from_json body
      if deletion_requests.all?
        route.query_parameters.clear
      else
        deletion_requests.each do |key, values|
          if values
            route.query_parameters[key]?.try do |existing|
              values.each do |value|
                existing.delete value
              end
            end
          else
            route.query_parameters.delete key
          end
        end
      end
      build_json context.response do |json|
        json.field "status", "success"
      end
    end
    raise Unauthorized.new context
  end
  relative_delete "/:id/route" do |context|
    Actions.has_access? context, Access::Update
    # TODO: remove the given route from the group

  end
  relative_delete "/:id" do |context|
    if Actions.has_access? context, Access::Update
      to_be_deleted = DppmRestApi.permissions_config
        .groups
        .index { |group| group.id == context.params.url["id"] }
      raise NoSuchGroup.new context, context.params.url["id"] if to_be_deleted.nil?
      group = DppmRestApi.permissions_config.groups[to_be_deleted]
      DppmRestApi.permissions_config.groups.delete_at to_be_deleted
      DppmRestApi.permissions_config.sync_to_disk
      build_json context.response do |response|
        response.field("successfullyDeletedGroup") { group.to_json response }
      end
    end
  end
end
