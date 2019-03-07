module DppmRestApi::Actions::Service
  describe DppmRestApi::Actions::Service do
    describe root_path do
      it "responds with OK" do
        get root_path
        response.status_code.should eq 200
      end
    end
    describe root_path "/status" do
      it "responds with OK" do
        get root_path "/status"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/boot" do
      it "responds with OK" do
        patch root_path "/:service/boot"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/reload" do
      it "responds with OK" do
        patch root_path "/:service/reload"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/restart" do
      it "responds with OK" do
        patch root_path "/:service/restart"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/start" do
      it "responds with OK" do
        patch root_path "/:service/start"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/status" do
      it "responds with OK" do
        patch root_path "/:service/status"
        response.status_code.should eq 200
      end
    end
    describe root_path "/:service/stop" do
      it "responds with OK" do
        patch root_path "/:service/stop"
        response.status_code.should eq 200
      end
    end
  end
end
