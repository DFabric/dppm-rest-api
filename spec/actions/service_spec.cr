require "../../src/actions"
require "../spec_helper"

describe DppmRestApi::Actions::Service do
  route = DppmRestApi::Actions::RelativeRoute.new "/service"

  describe route.root_path do
    it "responds with 401 Forbidden" do
      get route.root_path
      assert_unauthorized response
    end
  end

  describe "status" do
    path = route.root_path + "/status"

    it "responds with 401 Forbidden" do
      get path
      assert_unauthorized response
    end
  end

  describe "boot" do
    path = route.root_path + "/:service/boot"

    it "responds with 401 Forbidden" do
      put path
      assert_unauthorized response
    end
  end

  describe "reload" do
    path = route.root_path + "/:service/reload"

    it "responds with 401 Forbidden" do
      put path
      assert_unauthorized response
    end
  end

  describe "restart" do
    path = route.root_path + "/:service/restart"

    it "responds with 401 Forbidden" do
      put path
      assert_unauthorized response
    end
  end

  describe "start" do
    path = route.root_path + "/:service/start"

    it "responds with 401 Forbidden" do
      put path
      assert_unauthorized response
    end
  end

  describe "status" do
    path = route.root_path + "/:service/status"

    it "responds with 401 Forbidden" do
      get path
      assert_unauthorized response
    end
  end

  describe "stop" do
    path = route.root_path + "/:service/stop"

    it "responds with 401 Forbidden" do
      put path
      assert_unauthorized response
    end
  end
end
