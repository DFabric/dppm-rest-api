require "../src/config"
require "../src/ext/scrypt_password"

module DppmRestApi
  struct Config
    def initialize(@groups, @users)
    end

    def self.test_fixture!
      new groups: [
        Group.new(
          name: "super user",
          id: 0,
          permissions: {
            "/**" => Route.new(Access.super_user),
          }
        ),
        Group.new(
          name: "full access to the default namespace",
          id: 499,
          permissions: {
            "/**" => Route.new(
              permissions: Access.super_user,
              query_parameters: {"namespace" => ["default-namespace"]}
            ),
          }
        ),
        Group.new(
          name: "full access to Jim Oliver's namespace",
          id: 1000,
          permissions: {
            "/**" => Route.new(
              permissions: Access.super_user,
              query_parameters: {"namespace" => ["jim-oliver"]}
            ),
          }
        ),
      ], users: [
        User.new(
          name: "Administrator",
          groups: Set[0],
          api_key_hash: Scrypt::Password.create password: Fixtures::TEST_USER_RAW_API_KEYS[:admin]
        ),
        User.new(
          name: "Jim Oliver",
          groups: Set[499, 1000],
          api_key_hash: Scrypt::Password.create password: Fixtures::TEST_USER_RAW_API_KEYS[:normal_user]
        ),
      ]
    end
  end

  module Fixtures
    # The size of the test api keys.
    TEST_KEY_SIZE = 24
    # Filepaths to raw test API keys.
    TEST_USER_RAW_API_KEYS = {
      admin:       Random::Secure.base64(TEST_KEY_SIZE),
      normal_user: Random::Secure.base64(TEST_KEY_SIZE),
    }

    def permissions_config
      DppmRestApi::Config.test_fixture!
    end
  end
end
