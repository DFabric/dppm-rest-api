require "spec"
require "spec-kemal"
require "../src/dppm_rest_api"

def new_test_context(verb = "GET", path = "/api/test")
  backing_io = IO::Memory.new
  request = HTTP::Request.new verb, path
  response = HTTP::Server::Response.new backing_io
  { backing_io, HTTP::Server::Context.new(request, response) }
end
