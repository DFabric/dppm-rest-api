require "../spec_helper"

module DppmRestApi::Actions::Groups
  struct AddGroupResponse
    property data : NamedTuple(successfullyAddedGroup: Config::Group)
    include JSON::Serializable
  end

  SPEC_FAKE_PATH         = "/fake/path"
  SPEC_FAKE_ENCODED_PATH = URI.encode_www_form SPEC_FAKE_PATH

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
        DppmRestApi.permissions_config.groups.find(&.id.== 789).should eq test_group
      end
    end
  end

  describe "put #{fmt_route "/:id/route/:path/:access_level"}" do
    it "responds with 401 Forbidden" do
      put fmt_route "/1234/route/#{SPEC_FAKE_ENCODED_PATH}/all"
      assert_unauthorized response
    end

    it "adds a new path and changes the group's name." do
      SpecHelper.without_authentication! do
        put fmt_route("/1000/route/#{SPEC_FAKE_ENCODED_PATH}/create?name=test%20group"),
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[SPEC_FAKE_PATH].permissions.should eq Access::Create
        new_grp.permissions[SPEC_FAKE_PATH].query_parameters["q"].should eq ["param"]
        new_grp.name.should eq "test group"
      end
    end

    it "adds a query parameter to an existing path" do
      SpecHelper.without_authentication! do
        put fmt_route("/1000/route/#{SPEC_FAKE_ENCODED_PATH}/create?name=test%20group")
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions["/fake/path"].permissions.should eq Access::Create
        new_grp.permissions[SPEC_FAKE_PATH].query_parameters.empty?.should be_true
        put fmt_route("/1000/route/#{SPEC_FAKE_ENCODED_PATH}/create?name=test%20group"),
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[SPEC_FAKE_PATH].permissions.should eq Access::Create
        new_grp.permissions[SPEC_FAKE_PATH].query_parameters["q"].should eq ["param"]
      end
    end

    it "adds a second query parameter to the available ones on an existing route/query set" do
      SpecHelper.without_authentication! do
        put fmt_route("/1000/route/#{SPEC_FAKE_ENCODED_PATH}/create?name=test%20group"),
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[SPEC_FAKE_PATH].permissions.should eq Access::Create
        new_grp.permissions[SPEC_FAKE_PATH].query_parameters["q"].should eq ["param"]
        put fmt_route("/1000/route/#{SPEC_FAKE_ENCODED_PATH}/create?name=test%20group"),
          body: {"q" => ["another-param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[SPEC_FAKE_PATH].permissions.should eq Access::Create
        new_grp.permissions[SPEC_FAKE_PATH].query_parameters["q"].should eq ["param", "another-param"]
      end
    end

    it "raises an error if the group doesn't already exist" do
      SpecHelper.without_authentication! do
        put fmt_route "/1234/route/#{SPEC_FAKE_ENCODED_PATH}/read"
        response.status_code.should eq 404
        errors = ErrorResponse.from_json(response.body).errors
        error = errors.find { |e| e.type == "DppmRestApi::Actions::Groups::NoSuchGroup" }
        fail "\
          Expected #{errors.to_pretty_json} to include an error of type \
          DppmRestApi::Actions::Groups::NoSuchGroup" if error.nil?
        error.message.should eq "No group found with ID 1234"
      end
    end
  end

  describe "delete #{fmt_route "/:id/route/:path"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/123/route/" + SPEC_FAKE_ENCODED_PATH
      assert_unauthorized response
    end

    it "revokes a user's permission on a given route" do
      SpecHelper.without_authentication! do
        DppmRestApi.permissions_config
          .groups
          .find { |grp| grp.id == 499 }
          .not_nil!
          .permissions[SPEC_FAKE_PATH] = DppmRestApi::Config::Route.new Access::Read
        delete fmt_route "/499/route/" + SPEC_FAKE_ENCODED_PATH
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups
          .find { |grp| grp.id == 499 }
          .not_nil!
          .permissions[SPEC_FAKE_PATH]?.should be_nil
      end
    end

    it "responds with NOT FOUND when the path has already been deleted" do
      SpecHelper.without_authentication! do
        delete fmt_route "/499/route/" + SPEC_FAKE_ENCODED_PATH
        errors = ErrorResponse.from_json(response.body).errors
        errors.map(&.type).should contain "DppmRestApi::Actions::NotFound"
        errors.map(&.message).first.as(String).should contain "permissions"
        response.status_code.should eq HTTP::Status::NOT_FOUND.value
      end
    end
  end
  describe "delete #{fmt_route "/:id/param/:path"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/1234/param/" + SPEC_FAKE_ENCODED_PATH
      assert_unauthorized response
    end

    it "deletes all query parameters on a path" do
      SpecHelper.without_authentication! do
        default_group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == 499 }
        fail "\
          Group with full access to the default namespace not found when \
          searching by ID #499" if default_group_idx.nil?
        default_group = DppmRestApi.permissions_config.groups[default_group_idx]
        default_group.permissions[SPEC_FAKE_PATH] = Config::Route.new Access::Read, {"test" => ["param"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete fmt_route("/499/param/#{SPEC_FAKE_ENCODED_PATH}"), body: {queryParameters: nil}.to_json
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[SPEC_FAKE_PATH]
          .query_parameters
          .empty?
          .should be_true
      end
    end

    it "deletes just one query parameter on a path" do
      SpecHelper.without_authentication! do
        default_group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == 499 }
        fail "\
          Group with full access to the default namespace not found when \
          searching by ID #499" if default_group_idx.nil?
        default_group = DppmRestApi.permissions_config.groups[default_group_idx]
        default_group.permissions[SPEC_FAKE_PATH] = Config::Route.new Access::Read,
          {"test1" => ["param1", "param2"], "test2" => ["param1", "param2"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete fmt_route "/499/param/#{SPEC_FAKE_ENCODED_PATH}?test1"
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[SPEC_FAKE_PATH]
          .query_parameters["test1"]?.should be_nil
      end
    end

    it "deletes just one value for a query parameter on a path" do
      SpecHelper.without_authentication! do
        default_group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == 499 }
        fail "\
        Group with full access to the default namespace not found when \
        searching by ID #499" if default_group_idx.nil?
        default_group = DppmRestApi.permissions_config.groups[default_group_idx]
        default_group.permissions[SPEC_FAKE_PATH] = Config::Route.new Access::Read,
          {"test1" => ["param1", "param2"], "test2" => ["param1", "param2"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete fmt_route "/499/param/#{SPEC_FAKE_ENCODED_PATH}?test1=param1"
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[SPEC_FAKE_PATH]
          .query_parameters["test1"]?.should eq ["param2"]
      end
    end
  end

  describe "delete #{fmt_route "/:id"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/123"
      assert_unauthorized response
    end

    it "deletes a whole group" do
      SpecHelper.without_authentication! do
        delete fmt_route "/499"
        assert_no_error in: response
        DppmRestApi.permissions_config.groups.find { |grp| grp.id == 499 }.should be_nil
      end
    end
  end
end
