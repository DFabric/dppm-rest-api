require "../spec_helper"

describe DppmRestApi::User do
  describe "Administrator" do
    it "is a memeber of the 'super user' group" do
      DppmRestApi.permissions_config
        .user(named: "Administrator")
        .not_nil!
        .groups
        .includes?(DppmRestApi.permissions_config.group(named: "super user"))
        .should be_true
    end
  end
  describe "a mocked normal user" do
    pending "has access to the default namespace and it's own but not others" do
      user = DppmRestApi.permissions_config
        .user(authenticated_with: NormalUserAPIKey)
        .not_nil!
      user.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["default-namespace"]}),
        DppmRestApi::Access::Delete)).should be_truthy
      user.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["jim-oliver"]}),
        DppmRestApi::Access::Update)).should be_truthy
      user.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["admins-stuff"]}),
        DppmRestApi::Access::Read)).should be_falsey
    end
  end
end
