require "../spec_helper"

module DppmRestApi::Actions::Groups
  struct AddGroupResponse
    property data : NamedTuple(successfullyAddedGroup: Config::Group)
    include JSON::Serializable
  end

  describe "post #{self}" do
    it "responds with 401 Forbidden" do
      post fmt_route
      assert_unauthorized response
    end
    it "returns BAD REQUEST when there is no request body" do
      SpecHelper.without_authentication! do
        post fmt_route
        err = ErrorResponse.from_json response.body
        err.errors.first.type.should eq "DppmRestApi::Actions::BadRequest"
        err.errors.first.message.should eq "One must specify a group to add."
      end
    end
    it "adds a group" do
      SpecHelper.without_authentication! do
        test_group = Config::Group.new id: 789, name: "Test group",
          permissions: {"/**" => Config::Route.new Access.deny, {"test" => ["param"]}}
        post fmt_route, body: test_group.to_json
        assert_no_error in: response
        response_data = AddGroupResponse.from_json response.body
        response_data.data[:successfullyAddedGroup].should eq test_group
      end
    end
  end
  describe "put #{fmt_route "/:id/route/:path/:access_level"}" do
    it "responds with 401 Forbidden" do
      put fmt_route "/some%2Froute/route/#{URI.escape "some/path"}/all"
      assert_unauthorized response
    end
  end
  describe "put #{fmt_route "/:id/param"}" do
    it "responds with 401 Forbidden" do
      put fmt_route "/some-param/param"
      assert_unauthorized response
    end
  end
  describe "delete #{fmt_route "/:id/route"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/some%2Froute/route"
      assert_unauthorized response
    end
  end
  describe "delete #{fmt_route "/:id/param"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/some-param/param"
      assert_unauthorized response
    end
  end
end
