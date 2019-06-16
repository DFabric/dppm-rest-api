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

Kemal.config.env = "test"

# Set up the mock permissions.json

# the location
macro permissions_file!
  Path[__DIR__, "permissions.json"]
end

Spec.before_each do
  # write the data to the file.
  File.open permissions_file!, mode: "w" do |file|
    JSON.build file, indent: 2 do |io|
      DppmRestApi::Fixtures.test_permissions_config.to_json io
    end
  end
  # Run the server
  DppmRestApi.run Socket::IPAddress::LOOPBACK, DPPM::Prefix.default_dppm_config.port, __DIR__
end
# Clean up after ourselves
Spec.after_each do
  File.delete permissions_file! if File.exists? permissions_file!
end
