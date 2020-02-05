require "../../src/actions"
require "../spec_helper"

describe DppmRestApi::Actions::RelativeRoute do
  route = DppmRestApi::Actions::RelativeRoute.new "/spec_test" do
    relative_get do |_context|
      raise "some untyped exception"
    end
  end

  describe "error handling" do
    it "produces an Unauthorized error" do
      get route.root_path
      data = DppmRestApi::Actions::ErrorResponse.from_json response.body
      unless server_error = data.errors.find &.type.== "DppmRestApi::Actions::Unauthorized"
        fail "Unauthorized not found"
      end
      server_error.message.should eq "Unauthorized"
      server_error.status_code.should eq HTTP::Status::UNAUTHORIZED
    end
  end
end
