require "kemal"
require "kemal_jwt_auth"
require "json"

module DppmRestApi::Actions
  def self.auth_handler
    @@handler ||= KemalJWTAuth::Handler.new users: DppmRestApi.permissions_config
  end
end
