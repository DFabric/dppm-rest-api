require "../spec_helper"

module DppmRestApi::Actions::Service
  describe DppmRestApi::Actions::Service do
    describe fmt_route do
      pending "responds with 401 Forbidden" do
        get fmt_route
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/status") do
      pending "responds with 401 Forbidden" do
        get fmt_route "/status"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/boot") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/boot")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/reload") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/reload")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/restart") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/restart")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/start") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/start")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/status") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/status")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:service/stop") do
      pending "responds with 401 Forbidden" do
        put (pp! fmt_route "/some-service/stop")
        response.status_code.should eq 401
      end
    end
  end
end
