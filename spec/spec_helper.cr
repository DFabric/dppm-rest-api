require "spec"
require "spec-kemal"

CRLF                = "\r\n"
NORMAL_USER_API_KEY = Random::Secure.base64 48
PERMISSION_FILE     = Path[__DIR__, "permissions.json"]

Kemal.config.env = "test"
Kemal.config.logging = false

def new_test_context(verb = "GET", path = "/api/test")
  backing_io = IO::Memory.new
  request = HTTP::Request.new verb, path
  response = HTTP::Server::Response.new backing_io
  {backing_io, HTTP::Server::Context.new(request, response)}
end

DppmRestApi.run Socket::IPAddress::LOOPBACK, DPPM::Prefix.default_dppm_config.port, __DIR__

# Because the API key for the "normal user" is automatically generated, we
# need to update the configuration to match the key that was just generated.
usr = DppmRestApi.permissions_config.users.find { |user| user.name == "Jim Oliver" }.not_nil!
DppmRestApi.permissions_config.users.delete usr
usr.api_key_hash = Scrypt::Password.create NORMAL_USER_API_KEY
DppmRestApi.permissions_config.users << usr
DppmRestApi.permissions_config.write_to PERMISSION_FILE
