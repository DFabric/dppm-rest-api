module Fixtures
  # The size of the test api keys.
  TEST_KEY_SIZE = 24
  # Filepaths to raw test API keys.
  TEST_USER_RAW_API_KEYS = {
    admin:       Random::Secure.base64(TEST_KEY_SIZE),
    normal_user: Random::Secure.base64(TEST_KEY_SIZE),
  }

  extend self

  def permissions_config
    DppmRestApi::Config.new groups: [
      DppmRestApi::Config::Group.new(
        name: "super user",
        id: 0,
        permissions: {
          "/**" => DppmRestApi::Config::Route.new(DppmRestApi::Access.super_user),
        }
      ),
      DppmRestApi::Config::Group.new(
        name: "full access to the default namespace",
        id: 499,
        permissions: {
          "/**" => DppmRestApi::Config::Route.new(
            permissions: DppmRestApi::Access.super_user,
            query_parameters: {"namespace" => ["default-namespace"]}
          ),
        }
      ),
      DppmRestApi::Config::Group.new(
        name: "full access to Jim Oliver's namespace",
        id: 1000,
        permissions: {
          "/**" => DppmRestApi::Config::Route.new(
            permissions: DppmRestApi::Access.super_user,
            query_parameters: {"namespace" => ["jim-oliver"]}
          ),
        }
      ),
    ], users: [
      DppmRestApi::Config::User.new(
        name: "Administrator",
        groups: Set{0},
        api_key_hash: Scrypt::Password.create password: Fixtures::TEST_USER_RAW_API_KEYS[:admin]
      ),
      DppmRestApi::Config::User.new(
        name: "Jim Oliver",
        groups: Set{499, 1000},
        api_key_hash: Scrypt::Password.create password: Fixtures::TEST_USER_RAW_API_KEYS[:normal_user]
      ),
    ]
  end
end
