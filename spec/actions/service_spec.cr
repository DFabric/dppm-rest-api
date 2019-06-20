require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Service
  describe DppmRestApi::Actions::Service do
    describe fmt_route do
      it "responds with 401 Forbidden" do
        get fmt_route
        assert_unauthorized response
      end
    end
    describe (fmt_route "/status") do
      it "responds with 401 Forbidden" do
        get fmt_route "/status"
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/boot") do
      it "responds with 401 Forbidden" do
        put (fmt_route "/some-service/boot")
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/reload") do
      it "responds with 401 Forbidden" do
        put (fmt_route "/some-service/reload")
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/restart") do
      it "responds with 401 Forbidden" do
        put (fmt_route "/some-service/restart")
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/start") do
      it "responds with 401 Forbidden" do
        put (fmt_route "/some-service/start")
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/status") do
      it "responds with 401 Forbidden" do
        get (fmt_route "/some-service/status")
        assert_unauthorized response
      end
    end
    describe (fmt_route "/:service/stop") do
      it "responds with 401 Forbidden" do
        put (fmt_route "/some-service/stop")
        assert_unauthorized response
      end
    end
  end
end
