require "kemal"
require "jwt"
require "./ext/path"
require "./ext/dppm_prefix_pkg_file"
require "./access"
require "./actions/route_helpers"
require "./config"
require "./actions/*"

module DppmRestApi::Actions
  extend self
  include RouteHelpers

  API_DOCUMENT = Config::DEFAULT_DATA_DIR + "api-options.json"
  alias ConfigKeyError = DPPM::Prefix::Base::ConfigKeyError

  def self.encode(user_info)
    JWT.encode(payload: user_info.to_h, key: @@secret_key, algorithm: @@algorithm)
  end

  before_all do |context|
    context.response.content_type = "application/json"
  end

  RelativeRoute.new "/" do
    relative_post "sign_in" do |context|
      raise BadRequest.new(context) unless body = context.request.body

      if user_info = DppmRestApi.permissions_config.find_and_authenticate! body
        data = {
          token: encode user_info,
        }
        context.response.content_type = "application/json"
        data.to_json context.response
        context.response.flush
      else
        raise Unauthorized.new context
      end
    end

    relative_options do |context|
      File.open API_DOCUMENT do |file|
        context.response << file
      end
    end
  end

  class_property prefix : DPPM::Prefix { raise "No prefix set" }

  def authorized_user(context : HTTP::Server::Context, access : Access) : Config::User
    @@access_filter.call context, access
  end

  @@access_filter : Proc(HTTP::Server::Context, Access, Config::User) = ->default_access_filter(HTTP::Server::Context, Access)
  @@algorithm = JWT::Algorithm::HS256
  @@secret_key : String = Random::Secure.base64(32)

  # Returns the user if authorized.
  def default_access_filter(context : HTTP::Server::Context, permission : Access) : Config::User
    if token = (context.request.headers["X-Token"]? || context.params.query["auth"]?)
      payload, _ = JWT.decode token: token, key: @@secret_key, algorithm: @@algorithm
      user_hash = JWTCompatibleHash.new payload.size
      payload.as_h.each { |k, v| user_hash[k] = v.as_s? || v.as_i? || v.as_bool? }

      if received_user = Config::User.from_h hash: user_hash
        return received_user if DppmRestApi.permissions_config.group_view(received_user).find_group? do |group|
                                  group.can_access?(
                                    context.request.path,
                                    context.request.query_params,
                                    permission
                                  )
                                end
      end
    end
    raise Unauthorized.new context
  end
end
