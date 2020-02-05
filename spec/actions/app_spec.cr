require "../../src/actions"
require "../spec_helper"

struct AppConfigDataResponse
  include JSON::Serializable
  property data : String
end

describe DppmRestApi::Actions::App do
  route = DppmRestApi::Actions::RelativeRoute.new "/app"

  describe "/:app_name/config/:key" do
    it "responds with 401 Unauthorized" do
      get route.root_path + "/some-app/config/key"
      assert_unauthorized response
    end

    pending "returns a specific key's data" do
      SpecHelper.without_authentication! do
        get route.root_path + "/test-app/config/port"
        assert_no_error in: response
        body = response.body || fail "no body returned"
        AppConfigDataResponse.from_json(body).data.should eq "Test App"
      end
    end
  end

  describe "/:app_name/config" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/config"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/boot" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/some_app/service/boot"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/reload" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/some_app/service/reload"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/restart" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/some-app/service/restart"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/start" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/some-app/service/start"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/status" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/service/status"
      assert_unauthorized response
    end
  end

  describe "/:app_name/service/stop" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/some-app/service/stop"
      assert_unauthorized response
    end
  end

  describe "/:app_name/libs" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/libs"
      assert_unauthorized response
    end
  end

  describe "/:app_name/app" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/app"
      assert_unauthorized response
    end
  end

  describe "/:app_name/pkg" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/pkg"
      assert_unauthorized response
    end
  end

  describe "/:app_name/logs" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/some-app/logs"
      assert_unauthorized response
    end
  end

  describe "/:app_name" do
    it "responds with 401 Forbidden" do
      post route.root_path + "/some-pkg"
      assert_unauthorized response
    end
  end

  describe "/:app_name" do
    it "responds with 401 Forbidden" do
      delete route.root_path + "/some-app"
      assert_unauthorized response
    end
  end
end
