require "./spec_helper"

describe "#deny_access!" do
  backing_io = IO::Memory.new
  request = HTTP::Request.new "GET", "/api/test"
  response = HTTP::Server::Response.new backing_io
  ctx = HTTP::Server::Context.new request, response
  it "denies access" do
    deny_access! to: ctx
    ctx.response.status_code.should eq 401
    backing_io.rewind.gets_to_end.ends_with?("Forbidden.\r\n").should be_true
  end
end
