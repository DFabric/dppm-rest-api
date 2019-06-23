module Fixtures
  # Set up the mock permissions.json
  # the location
  PERMISSION_FILE = Path[__DIR__, "permissions.json"]

  # The size of the test api keys.
  TEST_KEY_SIZE = 24

  # Filepaths to raw test API keys.
  module UserRawApiKeys
    ADMIN       = Random::Secure.base64(TEST_KEY_SIZE)
    NORMAL_USER = Random::Secure.base64(TEST_KEY_SIZE)
  end

  PERMISSIONS_CONFIG = DppmRestApi::Config.new groups: [
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
      group_ids: Set{0},
      api_key_hash: Scrypt::Password.create password: UserRawApiKeys::ADMIN
    ),
    DppmRestApi::Config::User.new(
      name: "Jim Oliver",
      group_ids: Set{499, 1000},
      api_key_hash: Scrypt::Password.create password: UserRawApiKeys::NORMAL_USER
    ),
  ]

  # Set all configs to the expected values.
  def self.reset_config
    DppmRestApi.permissions_config = PERMISSIONS_CONFIG
    DppmRestApi.permissions_config.write_to PERMISSION_FILE
  end

  def self.new_config : DppmRestApi::Config
    File.open PERMISSION_FILE do |file|
      DppmRestApi::Config.from_json file
    end
  end
end
