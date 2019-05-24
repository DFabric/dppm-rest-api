require "json"

# :nodoc:
#
# This is used to parse the JSON-formatted request body
# when authenticating a user.
struct ReceivedUser
  include JSON::Serializable
  property! name : String
  property! auth : String
end
