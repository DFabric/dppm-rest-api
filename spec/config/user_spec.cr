require "../spec_helper"

describe DppmRestApi::Config::User do
  describe "Administrator" do
    it "is a memeber of the 'super user' group" do
      user = DppmRestApi.permissions_config.group_view(
        DppmRestApi.permissions_config
          .users
          .find { |usr| usr.name == "Administrator" }
          .not_nil!
      )

      user.groups
        .includes?(DppmRestApi.permissions_config.groups.find { |grp| grp.name == "super user" })
        .should be_true
    end
  end
  describe "a mocked normal user" do
    it "has access to the default namespace and it's own but not others" do
      user = DppmRestApi.permissions_config
        .users
        .find { |usr| usr.api_key_hash.verify Fixtures::UserRawApiKeys::NORMAL_USER }
        .not_nil!

      group_view = DppmRestApi.permissions_config.group_view user

      group_view.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["default-namespace"]}),
        DppmRestApi::Access::Delete)).should be_truthy
      group_view.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["jim-oliver"]}),
        DppmRestApi::Access::Update)).should be_truthy
      group_view.find_group?(&.can_access?(
        "/some/arbitrary/path",
        HTTP::Params.new({"namespace" => ["admins-stuff"]}),
        DppmRestApi::Access::Read)).should be_falsey
    end
  end
end
