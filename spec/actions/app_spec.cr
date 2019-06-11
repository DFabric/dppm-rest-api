require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::App
  describe DppmRestApi::Actions::App do
    describe (fmt_route "/:app_name/config/:key") do
      it "responds with 401 Unauthorized" do
        get fmt_route "/some-app/config/key"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/config/:key") do
      it "responds with 401 Forbidden" do
        post fmt_route "/some-app/config/key"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/config/:keys") do
      it "responds with 401 Forbidden" do
        delete fmt_route "/some-app/config/keys"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/config") do
      it "responds with 401 Forbidden" do
        get fmt_route "/some-app/config"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/boot") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some_app/service/boot")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/reload") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some_app/service/reload")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/restart") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some-app/service/restart")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/start") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some-app/service/start")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/status") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some-app/service/status")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/service/stop") do
      pending "responds with 401 Forbidden" do
        put (fmt_route "/some-app/service/stop")
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/libs") do
      it "responds with 401 Forbidden" do
        get fmt_route "/some-app/libs"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/app") do
      it "responds with 401 Forbidden" do
        get fmt_route "/some-app/app"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/pkg") do
      it "responds with 401 Forbidden" do
        get fmt_route "/some-app/pkg"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name/logs") do
      it "responds with 401 Forbidden" do
        get fmt_route "/some-app/logs"
        response.status_code.should eq 401
      end
    end
    pending "ws #{fmt_route "/:app_name/logs"}" do
      # spec-kemal has no way to test websocket routes
    end
    describe (fmt_route "/:package_name") do
      pending "responds with 401 Forbidden" do
        put fmt_route "/some-pkg"
        response.status_code.should eq 401
      end
    end
    describe (fmt_route "/:app_name") do
      it "responds with 401 Forbidden" do
        delete fmt_route "/some-app/"
        response.status_code.should eq 401
      end
    end
  end
end
