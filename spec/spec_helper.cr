require "spec"
require "spec-kemal"
require "../src/dppm_rest_api"

CRLF                = "\r\n"
NORMAL_USER_API_KEY = Path[__DIR__, "normal_user.api_key"]

macro permissions_file!
  Path[__DIR__, "permissions.json"]
end

def new_test_context(verb = "GET", path = "/api/test")
  backing_io = IO::Memory.new
  request = HTTP::Request.new verb, path
  response = HTTP::Server::Response.new backing_io
  {backing_io, HTTP::Server::Context.new(request, response)}
end

DppmRestApi.run Socket::IPAddress::LOOPBACK, Prefix.default_dppm_config.port, __DIR__
