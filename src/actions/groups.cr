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
      old_group = DppmRestApi.permissions_config.groups[index]?
      group = old_group.clone
      path = URI.unescape context.params.url["path"]
      access_level = Access.parse?(context.params.url["access_level"])
      raise InvalidAccessLevel.new context if access_level.nil?
      name = context.params.query["name"]?
      raise BadRequest.new context, "must specify a name for a new group" if name.nil?
      # Create the group if it doesn't already exist
      group ||= Config::Group.new id: group_id, name: name,
        permissions: {path => Config::Route.new access_level}
      # Create a query parameters object (since the default isn't nil, it's an
      # empty Hash) if group doesn't already have a path with query params on
      # it.
      existing_params = group.permissions[path]?
        .try &.query_parameters || {} of String => Array(String)
      # if there were query parameters specified in the body, override
      # existing values
      existing_params.merge query_params_in_body? of: context
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
  # Specifying null instead of the queryParameters object will delete all
  # parameter specifications on this route. Specifying null instead of a
  # list of values will delete that parameter from the group.
  relative_delete "/:id/param/:path/:access_level/" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: remove the given param from the group
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
