require "spec"
require "spec-kemal"
require "../src/dppm_rest_api"
require "./fixtures"

CRLF = "\r\n"

def new_test_context(verb = "GET", path = "/api/test")
  backing_io = IO::Memory.new
  request = HTTP::Request.new verb, path
  response = HTTP::Server::Response.new backing_io
  {backing_io, HTTP::Server::Context.new(request, response)}
end

# The only reason this is a macro is that a macro shows the location where it
# is expanded on failure, a def shows the location of the def.
macro assert_unauthorized(response)
  response.status_code.should eq 401
  found = DppmRestApi::ErrorResponse.from_json(response.body)
    .errors
    .find do |err|
      err.message == "Unauthorized" &&
        err.status_code == HTTP::Status::UNAUTHORIZED
    end
  fail "expected error response not found" unless found
end

module DppmRestApi
  # Disable all authentication checks by making `DppmRestApi::Actions.has_access?`
  # always return true, then set the authentication back to the default system
  # after yielding to the block.
  def self.without_authentication!
    Actions.access_filter = ->(_context : HTTP::Server::Context, _permissions : DppmRestApi::Access) { true }
    yield
  ensure
    Actions.access_filter = ->access_filter(HTTP::Server::Context, Access)
  end
end

@[AlwaysInline]
def without_authentication!
  DppmRestApi.without_authentication! { yield }
end

Kemal.config.env = "test"
Fixtures.reset_config

# Run the server
DppmRestApi.run Socket::IPAddress::LOOPBACK, DPPM::Prefix.default_dppm_config.port, __DIR__
# Set all configs back to the expected values, in case they changed
Spec.before_each do
  Fixtures.reset_config
  FileUtils.mkdir_p Fixtures::PREFIX_PATH
  DPPM::Prefix.new(Fixtures::PREFIX_PATH).create
end
# Clean up after ourselves
Spec.after_each do
  File.delete Fixtures::PERMISSION_FILE if File.exists? Fixtures::PERMISSION_FILE
  FileUtils.rm_rf Fixtures::PREFIX_PATH
end
