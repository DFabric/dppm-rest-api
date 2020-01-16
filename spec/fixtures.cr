struct Fixtures
  # Set up the mock permissions.json
  # the location
  DIR         = File.tempname "temp_dppm_api_dir"
  PREFIX_PATH = Path[DIR, "temp_dppm_prefix"]

  # The size of the test api keys.
  TEST_KEY_SIZE = 24

  # Filepaths to raw test API keys.
  module UserRawApiKeys
    ADMIN       = Random::Secure.base64 TEST_KEY_SIZE
    NORMAL_USER = Random::Secure.base64 TEST_KEY_SIZE
  end

  @permissions_config = DppmRestApi::Config.new groups: [
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
      id: UUID.random,
      name: "Administrator",
      group_ids: Set{0},
      api_key_hash: Scrypt::Password.create password: Fixtures::UserRawApiKeys::ADMIN
    ),
    DppmRestApi::Config::User.new(
      id: UUID.random,
      name: "Jim Oliver",
      group_ids: Set{499, 1000},
      api_key_hash: Scrypt::Password.create password: Fixtures::UserRawApiKeys::NORMAL_USER
    ),
  ], data_dir: DIR

  # Set all configs to the expected values.
  def reset_config
    DppmRestApi.permissions_config = @permissions_config
    DppmRestApi.permissions_config.sync_to_disk
  end

  def self.new_config : DppmRestApi::Config
    config = DppmRestApi::Config.read DIR
    config.sync_to_disk
    config
  end

  # Used by the user add route
  USER_BODY = DppmRestApi::Actions::User::AddUserBody.new name: "Mock user", groups: Set{0}
end
