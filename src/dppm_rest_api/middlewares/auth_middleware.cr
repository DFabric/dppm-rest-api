require "kemal"
require "kemal_jwt_auth"
require "../../config"
require "json"

module DppmRestApi::Actions
  # :nodoc:
  struct RecvdUser
    include JSON::Serializable
    property! name : String
    property! auth : String
  end

  # Implements the interface required by KemalJWTAuth in reference to an Array
  # of user
  class Users
    private property internal : Array(User)

    def initialize(@internal); end

    forward_missing_to :internal

    def find_and_authenticate!(body) : User?
      data = RecvdUser.from_json body
      if key = data.auth?
        if found = DppmRestApi.config.file.users.find { |user| user.api_key_hash == key }
          found.to_h
        end
      end
      nil
    rescue JSON::ParseException
      nil
    end
  end

  def self.auth_handler
    @@handler ||= KemalJWTAuth::Handler(Users, User).new users: Users.new DppmRestApi.config.file.users
  end
end
