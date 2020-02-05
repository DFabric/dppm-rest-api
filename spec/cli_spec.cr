require "./spec_helper"
require "../src/cli"

private def require_arg(arg, file = __FILE__, line = __LINE__, &block)
  it "requires the #{arg} argument", file, line do
    expect_raises RequiredArgument, message: "the argument '#{arg}' is required!" do
      block.call.not_nil!.body
    end
  end
end

describe DppmRestApi::CLI do
  describe "required" do
    it "raises an error for a null value" do
      null_val : String? = nil
      expect_raises RequiredArgument, message: "the argument 'null-val' is required!" do
        DppmRestApi::CLI.required null_val
      end
    end

    it "changes the type of a value" do
      nullable : String? = "something" || nil
      typeof(nullable).should eq String?
      DppmRestApi::CLI.required nullable
      typeof(nullable).should eq String
    end
  end

  describe "selected_users" do
    it "selects by name with regex" do
      mock_users = DppmRestApi.permissions_config.users
      selected = DppmRestApi::CLI.selected_users "/^Admin/", nil, nil, from: mock_users
      selected.size.should eq 1
      selected.first.name.should eq "Administrator"
      DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [0]
    end

    it "selects by name literals" do
      mock_users = DppmRestApi.permissions_config.users
      selected = DppmRestApi::CLI.selected_users "Administrator", nil, nil, from: mock_users
      selected.size.should eq 1
      selected.first.name.should eq "Administrator"
      DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [0]
    end

    {% for group_args in ["499,1000", "499"] %}
      context %<with group id {{group_args}}> do
        it "selects by group membership" do
          mock_users = DppmRestApi.permissions_config.users
          selected = DppmRestApi::CLI.selected_users nil, {{group_args}}, nil, from: mock_users
          selected.size.should eq 1
          selected.first.name.should eq "Jim Oliver"
          DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [499, 1000]
        end
      end
      {% end %}

    it "selects by api key" do
      mock_users = DppmRestApi.permissions_config.users
      selected = DppmRestApi::CLI.selected_users nil, nil, Fixtures::UserRawApiKeys::NORMAL_USER, from: mock_users
      selected.size.should eq 1
      selected.first.name.should eq "Jim Oliver"
      DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [499, 1000]
    end
  end

  describe "add_user" do
    it "adds a user" do
      key = DppmRestApi::CLI.add_user name: "added user", groups: "500", data_dir: Fixtures::DIR
      config = Fixtures.new_config
      if user = config.users.find { |usr| usr.name == "added user" }
        user.api_key_hash.verify(key).should be_true
        user.group_ids.should eq Set{500}
      else
        fail "user failed to be added"
      end
    end
  end

  require_arg "data-dir" do
    DppmRestApi::CLI.add_user name: "something", groups: "1,2,3", data_dir: nil
  end
  require_arg :name do
    DppmRestApi::CLI.add_user name: nil, groups: "1,2,3", data_dir: "/tmp"
  end
  require_arg :groups do
    DppmRestApi::CLI.add_user name: "somethign", groups: nil, data_dir: "/tmp"
  end

  describe "edit_users" do
    it "edits a user" do
      user_id = Fixtures.new_config.users.find { |user| user.name.starts_with? "Jim" }.not_nil!.id
      DppmRestApi::CLI.edit_users user_id: user_id,
        new_name: "changed name",
        add_groups: "500",
        remove_groups: "499",
        data_dir: Fixtures::DIR
      config = Fixtures.new_config
      config.users.find { |usr| usr.name == "Jim Oliver" }.should be_nil
      config.users.find { |usr| usr.name == "changed name" }.try(&.group_ids).should eq Set{500, 1000}
    end

    it "requires a valid user's UUID" do
      bogus_id = UUID.random
      expect_raises Exception, message: "No user found with id #{bogus_id}" do
        DppmRestApi::CLI.edit_users user_id: bogus_id, new_name: "xyz", data_dir: Fixtures::DIR, add_groups: nil, remove_groups: nil
      end
    end

    require_arg "data-dir" do
      DppmRestApi::CLI.edit_users user_id: nil,
        data_dir: nil,
        new_name: nil,
        add_groups: nil,
        remove_groups: nil
    end
    require_arg "user-id" do
      DppmRestApi::CLI.edit_users user_id: nil,
        data_dir: Fixtures::DIR,
        new_name: nil,
        add_groups: nil,
        remove_groups: nil
    end
  end

  describe "rekey_users" do
    it "rekeys a user" do
      admin = DppmRestApi.permissions_config
        .users
        .find { |usr| usr.name == "Administrator" }
        .not_nil!
      orig_key_hash = admin.api_key_hash
      new_key = DppmRestApi::CLI.rekey_users user_id: admin.id, data_dir: Fixtures::DIR

      admin = Fixtures.new_config.users.find { |usr| usr.name == "Administrator" }.not_nil!
      admin.api_key_hash.verify(new_key).should be_true
      orig_key_hash.verify(new_key).should be_false
    end
    require_arg "data-dir" do
      DppmRestApi::CLI.rekey_users user_id: nil, data_dir: nil
    end
  end

  describe "delete_users" do
    it "deletes a user" do
      DppmRestApi::CLI.delete_users user_id: Fixtures.new_config.users.find { |usr| usr.name == "Administrator" }.not_nil!.id, data_dir: Fixtures::DIR
      Fixtures.new_config.users.find { |usr| usr.name == "Administrator" }.should be_nil
    end
    require_arg "data-dir" do
      DppmRestApi::CLI.delete_users user_id: nil, data_dir: nil
    end
    require_arg "user-id" do
      DppmRestApi::CLI.delete_users user_id: nil, data_dir: Fixtures::DIR
    end
  end

  describe "show_users" do
    it "outputs the known userdata" do
      config = DppmRestApi::CLI.show_users data_dir: Fixtures::DIR,
        match_name: "/.*/",
        match_groups: nil,
        api_key: nil

      config.find(&.name.==("Administrator")).not_nil!.group_ids.should eq Set{0}
      config.find(&.name.==("Jim Oliver")).not_nil!.group_ids.should eq Set{499, 1000}
    end
    require_arg "data-dir" do
      DppmRestApi::CLI.show_users match_name: nil, match_groups: nil, api_key: nil, data_dir: nil
    end
  end

  describe "add_group" do
    require_arg :id do
      DppmRestApi::CLI.add_group id: nil, name: nil, permissions: nil, data_dir: nil
    end
    require_arg :name do
      DppmRestApi::CLI.add_group id: "12345", name: nil, permissions: nil, data_dir: nil
    end
    require_arg :permissions do
      DppmRestApi::CLI.add_group id: "23456", name: "permissions missing test", permissions: nil, data_dir: nil
    end
    require_arg "data-dir" do
      DppmRestApi::CLI.add_group id: "34567", name: "data-dir missing test", permissions: "technically not nil", data_dir: nil
    end

    it "adds a group" do
      new_grp_permissions = {"/pkg/**" => {permissions: DppmRestApi::Access::Read}}
      DppmRestApi::CLI.add_group(
        id: "1234",
        name: "test-added group",
        permissions: new_grp_permissions.to_json,
        data_dir: Fixtures::DIR)
      config = Fixtures.new_config
      config.groups.find { |group| group.id == 1234 }.should_not be_nil
      config.groups
        .find { |group| group.id == 1234 }
        .try(&.can_access? "/pkg/something", HTTP::Params.new, :read)
        .should be_true
    end
  end

  describe "edit_access" do
    it "throws an error when the group id is not a numeral" do
      expect_raises InvalidGroupID do
        DppmRestApi::CLI.edit_access id: "five",
          path: "/doesnt/matter",
          access: "Read",
          data_dir: Fixtures::DIR
      end
    end

    it "throws an error if the group doesn't exist" do
      expect_raises NoSuchGroup do
        DppmRestApi::CLI.edit_access id: "5",
          path: "/doesnt/matter",
          access: "Read",
          data_dir: Fixtures::DIR
      end
    end

    it "can make Administrator read-only" do
      DppmRestApi::CLI.edit_access id: "0",
        path: "/**",
        access: "Read",
        data_dir: Fixtures::DIR
      config = Fixtures.new_config
      if su = config.groups.find { |group| group.id == 0 }
        su.can_access?(
          "/literally/anything",
          HTTP::Params.new({} of String => Array(String)),
          DppmRestApi::Access::Read
        ).should be_true
        su.can_access?(
          "/literally/anything",
          HTTP::Params.new({} of String => Array(String)),
          DppmRestApi::Access::Update
        ).should be_false
        if route = su.permissions["/**"]?
          route.permissions.should eq DppmRestApi::Access::Read
          empty_params = {} of String => Array(String)
          route.query_parameters.should eq empty_params
        else
          fail %[route "/**" not found in #{su.permissions}]
        end
      else
        fail "didn't find a user with ID == 0"
      end
    end
  end

  describe "edit_group_query" do
    it "throws an error when the group id is not a numeral" do
      expect_raises InvalidGroupID do
        DppmRestApi::CLI.edit_group_query id: "five",
          path: "/doesnt/matter",
          data_dir: Fixtures::DIR,
          key: "something",
          add_glob: nil,
          remove_glob: nil
      end
    end

    it "throws an error if the group doesn't exist" do
      expect_raises NoSuchGroup do
        DppmRestApi::CLI.edit_group_query id: "5",
          path: "/doesnt/matter",
          data_dir: Fixtures::DIR,
          key: "something",
          add_glob: nil,
          remove_glob: nil
      end
    end

    it "can add a glob to a query" do
      DppmRestApi::CLI.edit_group_query id: "1000",
        path: "/**",
        data_dir: Fixtures::DIR,
        key: "test-key",
        add_glob: "test-glob",
        remove_glob: nil
      test_group = Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.not_nil!
      test_group.permissions["/**"]
        .query_parameters["test-key"]?
        .should eq ["test-glob"]
    end
  end

  describe "add_route" do
    it "can add a path to a group's #permissions values" do
      DppmRestApi::CLI.add_route id: "1000", access: "Read", path: "/some/path", data_dir: Fixtures::DIR
      test_group = Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.not_nil!
      test_group.permissions["/some/path"]?.should_not be_nil
    end
  end

  describe "delete_group" do
    it "can remove a group" do
      DppmRestApi::CLI.delete_group id: "1000", data_dir: Fixtures::DIR
      Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.should be_nil
    end
  end
end
