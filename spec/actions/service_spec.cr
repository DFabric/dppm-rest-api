require "../spec_helper"

module DppmRestApi::Actions::Service
  describe DppmRestApi::Actions::Service do
    describe root_path do
      it "responds with 401 Forbidden" do
        get root_path
        response.status_code.should eq 401
      end
    end
    describe (root_path "/status") do
      it "responds with 401 Forbidden" do
        get root_path "/status"
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/boot") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/boot")
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/reload") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/reload")
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/restart") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/restart")
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/start") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/start")
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/status") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/status")
        response.status_code.should eq 401
      end
    end
    describe (root_path "/:service/stop") do
      it "responds with 401 Forbidden" do
        put (pp! root_path "/some-service/stop")
        response.status_code.should eq 401
      end
    end
  end
end
