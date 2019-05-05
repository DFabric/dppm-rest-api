require "../spec_helper"

describe DppmRestApi::User do
  describe "Administrator" do
    it "is a memeber of the 'super user' group" do
      DppmRestApi.config
        .file
        .user(named: "Administrator")
        .not_nil!
        .groups
        .includes?(DppmRestApi.config.file.group(named: "super user"))
        .should be_true
    end
  end
  describe "a mocked normal user" do
    it "has access to the default namespace and it's own but not others" do
      user = DppmRestApi.config
        .file
        .user(authenticated_with: Fixtures::NormalUserAPIKey)
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
