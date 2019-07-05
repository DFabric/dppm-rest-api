module DppmRestApi::Actions::User
  struct AddUserBody
    include JSON::Serializable
    getter name : String
    getter groups : Set(Int32)

    # :nodoc:
    #
    # For testing
    def initialize(@name, @groups); end
  end

  extend self
  include RouteHelpers
  relative_post nil do |context|
    if Actions.has_access? context, Access::Create
      userdata = begin
        if body = context.request.body
          AddUserBody.from_json body
        else
          raise BadRequest.new context, "adding a user requires a request body"
        end
      rescue e : JSON::ParseException
        raise BadRequest.new context, cause: e
      end
      config_key, user = Config::User.create userdata.groups, userdata.name
      DppmRestApi.permissions_config.users << user
      DppmRestApi.permissions_config.sync_to_disk
      build_json context.response do |resp|
        resp.field "SuccessfullyAddedUser" do
          user.to_json resp, except: :api_key_hash
        end
        resp.field "AccessKey", config_key
      end
      next context
    end
    raise Unauthorized.new context
  end
  relative_delete nil do |context|
    if Actions.has_access? context, Access::Delete
      # TODO delete a user
      next context
    end
    raise Unauthorized.new context
  end
  relative_get nil do |context|
    if Actions.has_access? context, Access::Read
      # userdata = AddUserBody.from_json context.request.body
      # TODO delete a user
      next context
    end
    raise Unauthorized.new context
  end
end
