require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Pkg
  describe DppmRestApi::Actions::Pkg do
    describe "get all package config" do
      it "responds with 401 Forbidden" do
        get fmt_route nil
        assert_unauthorized response
      end
    end
    describe "clear unused packages (#{fmt_route "/clean"})" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/clean"
        assert_unauthorized response
      end
      it "responds that there are no packages to clean" do
        without_authentication! do
          delete fmt_route "/clean"
          # response.status_code.should eq 404
          data = ErrorResponse.from_json response.body
          error_msgs = data.errors.map &.message
          error_msgs.should contain "no packages to clean"
          error_msgs.should_not contain "received empty set from Prefix#clean_unused_packages; please report this strange bug"
        end
      end
    end
    describe "get /:id/query" do
      it "responds with 401 Forbidden" do
        get fmt_route "/package-id/query"
        assert_unauthorized response
      end
    end
    describe "delete a package (/:id/delete)" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/package-id/delete"
        assert_unauthorized response
      end
    end
  end
  describe "post fmt_route \"/:id/build\"" do
    it "responds with 401 Forbidden" do
      post fmt_route "/some-package/build"
      assert_unauthorized response
    end
  end
end
