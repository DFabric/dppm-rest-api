require "../spec_helper"

module DppmRestApi::Actions::App
  describe DppmRestApi::Actions::App do
    describe (root_path "/:app_name/config/:key") do
      it "responds with 401 Unauthorized" do
        get root_path "/some-app/config/key"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/config/:key") do
      it "responds with 401 Forbidden" do
        post root_path "/some-app/config/key"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/config/:keys") do
      it "responds with 401 Forbidden" do
        delete root_path "/some-app/config/keys"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/config") do
      it "responds with 401 Forbidden" do
        get root_path "/some-app/config"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/boot") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/boot"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/reload") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/reload"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/restart") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/restart"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/start") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/start"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/status") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/status"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/service/stop") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-app/service/stop"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/libs") do
      it "responds with 401 Forbidden" do
        get root_path "/some-app/libs"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/app") do
      it "responds with 401 Forbidden" do
        get root_path "/some-app/app"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/pkg") do
      it "responds with 401 Forbidden" do
        get root_path "/some-app/pkg"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name/logs") do
      it "responds with 401 Forbidden" do
        get root_path "/some-app/logs"
        response.status_code.should eq 401
      end
    end
    pending "ws #{root_path}/:app_name/logs" do
      # spec-kemal has no way to test websocket routes
    end
    describe (root_path "/:package_name") do
      it "responds with 401 Forbidden" do
        patch root_path "/some-pkg"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:app_name") do
      it "responds with 401 Forbidden" do
        delete root_path "/some-app/"
        response.status_code.should eq 401
      end
    end
  end
end
