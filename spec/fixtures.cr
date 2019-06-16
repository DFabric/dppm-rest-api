require "../src/access"
require "../src/ext/scrypt_password"

module DppmRestApi
  module Fixtures
    # The size of the test api keys.
    TEST_KEY_SIZE = 24
    # Filepaths to raw test API keys.
    TEST_USER_RAW_API_KEYS = {
      admin:       Random::Secure.base64(TEST_KEY_SIZE),
      normal_user: Random::Secure.base64(TEST_KEY_SIZE),
    }

    # The data which will be written to a permissions.json for use within
    # spec runs.
    class_property test_permissions_config = {
      groups: [
        {
          name:        "super user",
          id:          0,
          permissions: {
            "/**": {
              permissions: Access.super_user,
            },
          },
        }, {
          name:        "full access to the default namespace",
          id:          499,
          permissions: {
            "/**": {
              permissions:      Access.super_user,
              query_parameters: {
                "namespace": ["default-namespace"],
              },
            },
          },
        }, {
          name:        "full access to Jim Oliver's namespace",
          id:          1000,
          permissions: {
            "/**": {
              permissions:      Access.super_user,
              query_parameters: {
                "namespace": ["jim-oliver"],
              },
            },
          },
        },
      ], users: [
        {
          api_key_hash: Scrypt::Password.create(TEST_USER_RAW_API_KEYS[:admin]),
          groups:       [0],
          name:         "Administrator",
        },
        {
          api_key_hash: Scrypt::Password.create(TEST_USER_RAW_API_KEYS[:normal_user]),
          groups:       [499, 1000],
          name:         "Jim Oliver",
        },
      ],
    }
  end
end
