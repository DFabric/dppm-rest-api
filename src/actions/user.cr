require "../config/helpers"

module DppmRestApi::Actions::User
  extend self
  include Route
  include Config::Helpers

  struct AddUserBody
    include JSON::Serializable
    getter name : String
    getter groups : Set(Int32)

    # :nodoc:
    #
    # For testing
    def initialize(@name, @groups); end
  end

  def optional_query_param(context : HTTP::Server::Context, key : String)
    context.params.query[key]?.try do |value|
      URI.decode value
    end
  end

  def selected_users_from_query(context)
    selected_users(
      match_name: optional_query_param(context, "match_name"),
      match_groups: optional_query_param(context, "match_groups"),
      api_key: optional_query_param(context, "api_key"),
      from: DppmRestApi.permissions_config.users
    )
  end

  RelativeRoute.new "/user" do
    relative_post do |context|
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
      build_json_object context.response do |resp|
        resp.field "SuccessfullyAddedUser" do
          user.to_json resp, except: :api_key_hash
        end
        resp.field "AccessKey", config_key
      end
    end

    relative_delete "/:id" do |context|
      user_id = UUID.new context.params.url["id"]
      DppmRestApi.permissions_config.users.reject! { |user| user.id == user_id }
      DppmRestApi.permissions_config.sync_to_disk
      build_json_object context.response do |json|
        json.field "status", "success"
      end
    end

    relative_get do |context|
      build_json_object context.response do |response|
        response.field "users" do
          selected_users_from_query(context).to_json response
        end
      end
    end

    relative_get "/me" do |context, user|
      build_json_object context.response do |response|
        response.field "currentUser" do
          user.to_json response, except: :api_key_hash
        end
      end
      context.response.flush
    end
  end
end
