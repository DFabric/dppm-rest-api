require "../spec_helper"
require "../../src/actions/route_helpers"

module DppmRestApi::Actions
  module Spec
    extend self
    include RouteHelpers
    relative_get "/test" do |_context|
      raise "some untyped exception"
    end

    describe "error handling within relative_{{method}} route handlers" do
      it "produces an Unauthorized error" do
        get fmt_route "/test"
        data = ErrorResponse.from_json response.body
        unless server_error = data.errors.find &.type.== "DppmRestApi::Actions::Unauthorized"
          fail "Unauthorized not found"
        end
        server_error.message.should eq "Unauthorized"
        server_error.status_code.should eq HTTP::Status::UNAUTHORIZED
      end
    end
  end
end
