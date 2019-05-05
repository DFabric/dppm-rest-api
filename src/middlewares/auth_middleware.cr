require "kemal"
require "kemal_jwt_auth"
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
    private property internal : Array(Config::User)

    # Initialize from an array of User. I.E.
    #
    # ```
    # @users = Users.new array: [some, users]
    # # The Users can be authenticated with find_and_authenticate!
    # @users.find_and_authenticate! context.request.body
    # # They can also be iterated over as an Array(User)
    # @users.find { |user| user.name == expected }
    # ```
    def initialize(array @internal : Array(Config::User)); end

    forward_missing_to @internal

    def find_and_authenticate!(body) : Config::User?
      data = RecvdUser.from_json body
      if key = data.auth?
        DppmRestApi.permissions_config.users.find { |user| user.api_key_hash == key }
      end
    rescue JSON::ParseException
      nil
    end
  end

  class_property configured_users : Users { Users.new DppmRestApi.permissions_config.users }

  def self.auth_handler
    @@handler ||= KemalJWTAuth::Handler(Users, Config::User).new users: self.configured_users
  end
end
