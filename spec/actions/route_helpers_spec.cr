require "../spec_helper"
require "../../src/actions/route_helpers"

module DppmRestApi
  module Spec
    include Actions::RouteHelpers
    relative_get "/test" do |_context|
      raise "some untyped exception"
    end
    describe "error handling within relative_{{method}} route handlers" do
      it "catches an untyped error and converts it to InternalServerError" do
        get fmt_route "/test"
        data = ErrorResponse.from_json response.body
        untyped = (
          data.errors.find { |error| error.type == "Exception" } ||
          fail "untyped exception not found"
        )
        untyped.message.should eq "some untyped exception"
        untyped.status_code.should be_nil
        server_error = (
          data.errors.find { |error| error.type == "DppmRestApi::InternalServerError" } ||
          fail "InternalServerError not found"
        )
        server_error.message.should eq "Internal Server Error"
        server_error.status_code.should eq HTTP::Status::INTERNAL_SERVER_ERROR
      end
    end
  end
end
