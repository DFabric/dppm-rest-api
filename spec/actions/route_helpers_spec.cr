require "../spec_helper"
require "../../src/actions/route_helpers"

module DppmRestApi::Actions
  module Spec
    include RouteHelpers
    relative_get "/test" do |_context|
      raise "some untyped exception"
    end
    describe "error handling within relative_{{method}} route handlers" do
      it "catches an untyped error and converts it to InternalServerError" do
        get fmt_route "/test"
        data = ErrorResponse.from_json response.body
        unless untyped = data.errors.find { |error| error.type == "Exception" }
          fail "untyped exception not found"
        end
        untyped.message.should eq "some untyped exception"
        untyped.status_code.should be_nil
        unless server_error = data.errors.find { |error| error.type == "DppmRestApi::Actions::InternalServerError" }
          fail "InternalServerError not found"
        end
        server_error.message.should eq "Internal Server Error"
        server_error.status_code.should eq HTTP::Status::INTERNAL_SERVER_ERROR
      end
    end
  end
end
