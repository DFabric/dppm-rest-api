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
  found = DppmRestApi::Actions::ErrorResponse.from_json(response.body)
    .errors
    .find do |err|
      err.message == "Unauthorized" &&
        err.status_code == HTTP::Status::UNAUTHORIZED
    end
  fail "expected error response not found" unless found
end

def assert_no_error(in response : HTTP::Client::Response) : Nil
  return if response.status_code == 200
  response_errors = String.build do |str|
    str << "Failure! Reponse status code was #{response.status_code}\n"
    DppmRestApi::Actions::ErrorResponse.from_json(response.body).errors.each do |error|
      str << '\t' << error.type << ": " << error.message
      str << "\n\t resulting in status_code code " << error.status_code if error.status_code
      str << "\n\n"
    end
  end
  fail response_errors
end

module DppmRestApi::SpecHelper
  def SpecHelper.without_authentication!
    Actions.access_filter = ->(_context : HTTP::Server::Context, _permissions : DppmRestApi::Access) { true }
    yield
  ensure
    Actions.access_filter = ->DppmRestApi.access_filter(HTTP::Server::Context, Access)
  end
end

Spec.before_suite do
  DPPM::Logger.output = DPPM::Logger.error = File.open File::NULL, "w"
  Kemal.config.env = "test"
  FileUtils.mkdir_p Fixtures::DIR

  Fixtures.new.reset_config
  # Run the server
  DppmRestApi.run Socket::IPAddress::LOOPBACK,
    DPPM::Prefix.default_dppm_config.port,
    Fixtures::DIR,
    DPPM::Prefix.new(Fixtures::PREFIX_PATH.to_s).tap &.create
end

Spec.after_suite do
  FileUtils.rm_rf Fixtures::DIR
end

# Set all configs back to the expected values, in case they changed
Spec.before_each do
  FileUtils.mkdir_p Fixtures::DIR.to_s
  Fixtures.new.itself.reset_config
  FileUtils.mkdir_p Fixtures::PREFIX_PATH.to_s
  DppmRestApi::Actions.prefix.create
  FileUtils.cp_r "./lib/dppm/spec/samples", DppmRestApi::Actions.prefix.src.to_s
end
# Clean up after ourselves
Spec.after_each do
  File.delete Fixtures::PERMISSION_FILE if File.exists? Fixtures::PERMISSION_FILE
  FileUtils.rm_rf DppmRestApi::Actions.prefix.path.to_s
end
