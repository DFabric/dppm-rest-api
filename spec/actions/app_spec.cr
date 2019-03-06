module DppmRestApi::Actions::App
  describe DppmRestApi::Actions::App do
    describe "#{root_path}/:app_name/config/:key" do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/config/:key"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/config/:key" do
      it "responds with 200 OK" do
        post "#{root_path}/:app_name/config/:key"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/config/:keys" do
      it "responds with 200 OK" do
        delete "#{root_path}/:app_name/config/:keys"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/config" do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/config"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/boot" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/boot"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/reload" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/reload"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/restart" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/restart"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/start" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/start"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/status" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/status"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/service/stop" do
      it "responds with 200 OK" do
        patch "#{root_path}/:app_name/service/stop"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/libs" do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/libs"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/app" do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/app"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/pkg" do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/pkg"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name/logs"  do
      it "responds with 200 OK" do
        get "#{root_path}/:app_name/logs"
        response.status_code.should eq 200
      end
    end
    pending "ws #{root_path}/:app_name/logs" do
	  # spec-kemal has no way to test websocket routes
    end
    describe "#{root_path}/:package_name" do
      it "responds with 200 OK" do
        patch "#{root_path}/:package_name"
        response.status_code.should eq 200
      end
    end
    describe "#{root_path}/:app_name" do
      it "responds with 200 OK" do
        delete "#{root_path}/:app_name"
        response.status_code.should eq 200
      end
    end
  end
end
