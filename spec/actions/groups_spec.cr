require "../spec_helper"

struct AddGroupResponse
  property data : NamedTuple(successfullyAddedGroup: DppmRestApi::Config::Group)
  include JSON::Serializable
end

describe DppmRestApi::Actions::Groups do
  spec_fake_path = "/fake/path"
  spec_fake_encoded_path = URI.encode_www_form spec_fake_path
  route = DppmRestApi::Actions::RelativeRoute.new "/groups"

  describe "post" do
    it "responds with 401 Forbidden" do
      post route.root_path
      assert_unauthorized response
    end

    it "returns BAD REQUEST when there is no request body" do
      SpecHelper.without_authentication! do
        post route.root_path
        err = DppmRestApi::Actions::ErrorResponse.from_json response.body
        err.errors.first.type.should eq "DppmRestApi::Actions::BadRequest"
        err.errors.first.message.should eq "One must specify a group to add."
      end
    end

    it "adds a group" do
      SpecHelper.without_authentication! do
        test_group = DppmRestApi::Config::Group.new id: 789, name: "Test group",
          permissions: {"/**" => DppmRestApi::Config::Route.new DppmRestApi::Access.deny, {"test" => ["param"]}}
        post route.root_path, body: test_group.to_json
        assert_no_error in: response
        DppmRestApi.permissions_config.groups.find(&.id.== 789).should eq test_group
      end
    end
  end

  describe "put #{route.root_path + "/:id/route/:path/:access_level"}" do
    it "responds with 401 Forbidden" do
      put route.root_path + "/1234/route/#{spec_fake_encoded_path}/all"
      assert_unauthorized response
    end

    it "adds a new path and changes the group's name." do
      SpecHelper.without_authentication! do
        put route.root_path + "/1000/route/" + spec_fake_encoded_path + "/create?name=test%20group",
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[spec_fake_path].permissions.should eq DppmRestApi::Access::Create
        new_grp.permissions[spec_fake_path].query_parameters["q"].should eq ["param"]
        new_grp.name.should eq "test group"
      end
    end

    it "adds a query parameter to an existing path" do
      SpecHelper.without_authentication! do
        put route.root_path + "/1000/route/" + spec_fake_encoded_path + "/create?name=test%20group"
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions["/fake/path"].permissions.should eq DppmRestApi::Access::Create
        new_grp.permissions[spec_fake_path].query_parameters.empty?.should be_true
        put route.root_path + "/1000/route/" + spec_fake_encoded_path + "/create?name=test%20group",
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[spec_fake_path].permissions.should eq DppmRestApi::Access::Create
        new_grp.permissions[spec_fake_path].query_parameters["q"].should eq ["param"]
      end
    end

    it "adds a second query parameter to the available ones on an existing route/query set" do
      SpecHelper.without_authentication! do
        put route.root_path + "/1000/route/" + spec_fake_encoded_path + "/create?name=test%20group",
          body: {"q" => ["param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[spec_fake_path].permissions.should eq DppmRestApi::Access::Create
        new_grp.permissions[spec_fake_path].query_parameters["q"].should eq ["param"]
        put route.root_path + "/1000/route/" + spec_fake_encoded_path + "/create?name=test%20group",
          body: {"q" => ["another-param"]}.to_json
        assert_no_error in: response
        new_grp = DppmRestApi.permissions_config.groups.find(&.id.== 1000)
        fail "group with ID 1000 not found" if new_grp.nil?
        new_grp.permissions[spec_fake_path].permissions.should eq DppmRestApi::Access::Create
        new_grp.permissions[spec_fake_path].query_parameters["q"].should eq ["param", "another-param"]
      end
    end

    it "raises an error if the group doesn't already exist" do
      SpecHelper.without_authentication! do
        put route.root_path + "/1234/route/#{spec_fake_encoded_path}/read"
        response.status_code.should eq 404
        errors = DppmRestApi::Actions::ErrorResponse.from_json(response.body).errors
        error = errors.find { |e| e.type == "DppmRestApi::Actions::Groups::NoSuchGroup" }
        fail "\
          Expected #{errors.to_pretty_json} to include an error of type \
          DppmRestApi::Actions::Groups::NoSuchGroup" if error.nil?
        error.message.should eq "No group found with ID 1234"
      end
    end
  end

  describe "delete #{route.root_path + "/:id/route/:path"}" do
    it "responds with 401 Forbidden" do
      delete route.root_path + "/123/route/" + spec_fake_encoded_path
      assert_unauthorized response
    end

    it "revokes a user's permission on a given route" do
      SpecHelper.without_authentication! do
        DppmRestApi.permissions_config
          .groups
          .find { |grp| grp.id == 499 }
          .not_nil!
          .permissions[spec_fake_path] = DppmRestApi::Config::Route.new DppmRestApi::Access::Read
        delete route.root_path + "/499/route/" + spec_fake_encoded_path
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups
          .find { |grp| grp.id == 499 }
          .not_nil!
          .permissions[spec_fake_path]?.should be_nil
      end
    end

    it "responds with NOT FOUND when the path has already been deleted" do
      SpecHelper.without_authentication! do
        delete route.root_path + "/499/route/" + spec_fake_encoded_path
        errors = DppmRestApi::Actions::ErrorResponse.from_json(response.body).errors
        errors.map(&.type).should contain "DppmRestApi::Actions::NotFound"
        errors.map(&.message).first.as(String).should contain "permissions"
        response.status_code.should eq HTTP::Status::NOT_FOUND.value
      end
    end
  end

  describe "delete #{route.root_path + "/:id/param/:path"}" do
    it "responds with 401 Forbidden" do
      delete route.root_path + "/1234/param/" + spec_fake_encoded_path
      assert_unauthorized response
    end

    it "deletes all query parameters on a path" do
      SpecHelper.without_authentication! do
        default_group_idx = DppmRestApi.permissions_config.groups.index { |grp| grp.id == 499 }
        fail "\
          Group with full access to the default namespace not found when \
          searching by ID #499" if default_group_idx.nil?
        default_group = DppmRestApi.permissions_config.groups[default_group_idx]
        default_group.permissions[spec_fake_path] = DppmRestApi::Config::Route.new DppmRestApi::Access::Read, {"test" => ["param"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete route.root_path + "/499/param/" + spec_fake_encoded_path, body: {queryParameters: nil}.to_json
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[spec_fake_path]
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
        default_group.permissions[spec_fake_path] = DppmRestApi::Config::Route.new DppmRestApi::Access::Read,
          {"test1" => ["param1", "param2"], "test2" => ["param1", "param2"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete route.root_path + "/499/param/" + spec_fake_encoded_path + "?test1"
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[spec_fake_path]
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
        default_group.permissions[spec_fake_path] = DppmRestApi::Config::Route.new DppmRestApi::Access::Read,
          {"test1" => ["param1", "param2"], "test2" => ["param1", "param2"]}
        DppmRestApi.permissions_config.groups[default_group_idx] = default_group
        DppmRestApi.permissions_config.sync_to_disk
        delete route.root_path + "/499/param/" + spec_fake_encoded_path + "?test1=param1"
        assert_no_error in: response
        DppmRestApi.permissions_config
          .groups[default_group_idx]
          .permissions[spec_fake_path]
          .query_parameters["test1"]?.should eq ["param2"]
      end
    end
  end

  describe "delete #{route.root_path + "/:id"}" do
    it "responds with 401 Forbidden" do
      delete route.root_path + "/123"
      assert_unauthorized response
    end

    it "deletes a whole group" do
      SpecHelper.without_authentication! do
        delete route.root_path + "/499"
        assert_no_error in: response
        DppmRestApi.permissions_config.groups.find { |grp| grp.id == 499 }.should be_nil
      end
    end
  end
end
