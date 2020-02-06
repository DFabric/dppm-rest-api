require "kemal"
require "jwt"
require "./ext/path"
require "./ext/dppm/*"
require "./access"
require "./actions/route"
require "./actions/relative_route"
require "./config"
require "./actions/*"

module DppmRestApi::Actions
  extend self

  API_DOCUMENT = Config::DEFAULT_DATA_DIR + "api-options.json"
  alias ConfigKeyError = DPPM::Prefix::Base::ConfigKeyError

  before_all do |context|
    context.response.content_type = "application/json"
  end

  post "/sign_in" do |context|
    raise BadRequest.new(context) unless body = context.request.body

    if user_info = DppmRestApi.permissions_config.find_and_authenticate! body
      data = {
        token: RelativeRoute.encode user_info,
      }
      context.response.content_type = "application/json"
      data.to_json context.response
      context.response.flush
    else
      raise Unauthorized.new context
    end
  end

  options "/" do |context|
    File.open API_DOCUMENT do |file|
      context.response << file
    end
  end
end
