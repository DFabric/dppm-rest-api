require "./spec_helper"
require "../src/cli"

module DppmRestApi::CLI
  private def require_arg(arg, file = __FILE__, line = __LINE__, &block)
    it "requires the #{arg} argument", file, line do
      expect_raises RequiredArgument, message: "the argument '#{arg}' is required!" do
        block.call.not_nil!.body
      end
    end
  end

  describe "CLI methods" do
    describe "required" do
      it "raises an error for a null value" do
        null_val : String? = nil
        expect_raises RequiredArgument, message: "the argument 'null-val' is required!" do
          required null_val
        end
      end
      it "changes the type of a value" do
        nullable : String? = "something" || nil
        typeof(nullable).should eq String?
        required nullable
        typeof(nullable).should eq String
      end
    end
    describe "#selected_users" do
      it "selects by name with regex" do
        mock_users = DppmRestApi.permissions_config.users
        selected = selected_users "/^Admin/", nil, nil, from: mock_users
        selected.size.should eq 1
        selected.first.name.should eq "Administrator"
        DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [0]
      end
      it "selects by name literals" do
        mock_users = DppmRestApi.permissions_config.users
        selected = selected_users "Administrator", nil, nil, from: mock_users
        selected.size.should eq 1
        selected.first.name.should eq "Administrator"
        DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [0]
      end
      {% for group_args in ["499,1000", "499"] %}
      context %<with group id {{group_args}}> do
        it "selects by group membership" do
          mock_users = DppmRestApi.permissions_config.users
          selected = selected_users nil, {{group_args}}, nil, from: mock_users
          selected.size.should eq 1
          selected.first.name.should eq "Jim Oliver"
          DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [499, 1000]
        end
      end
      {% end %}
      it "selects by api key" do
        mock_users = DppmRestApi.permissions_config.users
        selected = selected_users nil, nil, Fixtures::UserRawApiKeys::NORMAL_USER, from: mock_users
        selected.size.should eq 1
        selected.first.name.should eq "Jim Oliver"
        DppmRestApi.permissions_config.group_view(selected.first).groups.map(&.id).should eq [499, 1000]
      end
    end
    describe "#add_user" do
      it "adds a user" do
        tmp = File.tempname
        add_user name: "added user", groups: "500", data_dir: __DIR__, output_file: tmp
        key = File.read_lines(tmp)[1]
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
      add_user name: "something", groups: "1,2,3", data_dir: nil, output_file: nil
    end
    require_arg :name do
      add_user name: nil, groups: "1,2,3", data_dir: "/tmp", output_file: nil
    end
    require_arg :groups do
      add_user name: "somethign", groups: nil, data_dir: "/tmp", output_file: nil
    end
  end
  describe "#edit_users" do
    it "edits a user" do
      edit_users match_name: "/^Jim/",
        match_groups: nil,
        api_key: nil,
        new_name: "changed name",
        add_groups: "500",
        remove_groups: "499",
        data_dir: __DIR__
      config = Fixtures.new_config
      config.users.find { |usr| usr.name == "Jim Oliver" }.should be_nil
      config.users.find { |usr| usr.name == "changed name" }.try(&.group_ids).should eq Set{500, 1000}
    end
    require_arg "data-dir" do
      edit_users match_name: nil,
        match_groups: nil,
        api_key: nil,
        data_dir: nil,
        new_name: nil,
        add_groups: nil,
        remove_groups: nil
    end
  end
  describe "#rekey_users" do
    it "rekeys a user" do
      data_file = File.tempfile
      orig_key_hash = DppmRestApi.permissions_config
        .users
        .find { |usr| usr.name == "Administrator" }
        .not_nil!
        .api_key_hash
      rekey_users match_name: "Administrator",

        match_groups: nil,
        api_key: nil,
        data_dir: __DIR__,
        output_file: data_file.path
      new_key = File.read_lines(data_file.path)[1]
      Fixtures.new_config.users.find { |usr| usr.name == "Administrator" }.not_nil!.api_key_hash.verify(new_key).should be_true
      orig_key_hash.should_not eq new_key
    end
    require_arg "data-dir" do
      delete_users match_name: nil, match_groups: nil, api_key: nil, data_dir: nil
    end
  end
  describe "#delete_users" do
    it "deletes a user" do
      delete_users match_name: nil, match_groups: "0", api_key: nil, data_dir: __DIR__
      Fixtures.new_config.users.find { |usr| usr.name == "Administrator" }.should be_nil
    end
    require_arg "data-dir" do
      delete_users match_name: nil, match_groups: nil, api_key: nil, data_dir: nil
    end
  end
  describe "#show_users" do
    it "outputs the known userdata" do
      tmp = File.tempname "permissions", ".json"
      show_users data_dir: __DIR__,
        output_file: tmp,
        match_name: "/.*/",
        match_groups: nil,
        api_key: nil
      File.open tmp do |file|
        config = Array(Config::User).from_json file
        config.find(&.name.==("Administrator")).not_nil!.group_ids.should eq Set{0}
        config.find(&.name.==("Jim Oliver")).not_nil!.group_ids.should eq Set{499, 1000}
      end
      File.delete tmp
    end
    require_arg "data-dir" do
      delete_users match_name: nil, match_groups: nil, api_key: nil, data_dir: nil
    end
  end
  describe "#add_group" do
    require_arg :id do
      add_group id: nil, name: nil, permissions: nil, data_dir: nil
    end
    require_arg :name do
      add_group id: "12345", name: nil, permissions: nil, data_dir: nil
    end
    require_arg :permissions do
      add_group id: "23456", name: "permissions missing test", permissions: nil, data_dir: nil
    end
    require_arg "data-dir" do
      add_group id: "34567", name: "data-dir missing test", permissions: "technically not nil", data_dir: nil
    end
    it "adds a group" do
      new_grp_permissions = {"/pkg/**" => {permissions: DppmRestApi::Access::Read}}
      add_group(
        id: "1234",
        name: "test-added group",
        permissions: new_grp_permissions.to_json,
        data_dir: __DIR__)
      config = Fixtures.new_config
      config.groups.find { |group| group.id == 1234 }.should_not be_nil
      config.groups
        .find { |group| group.id == 1234 }
        .try(&.can_access? "/pkg/something", HTTP::Params.new, Access::Read)
        .should be_true
    end
  end
  describe "#edit_access" do
    it "throws an error when the group id is not a numeral" do
      expect_raises InvalidGroupID do
        edit_access id: "five",
          path: "/doesnt/matter",
          access: "Read",
          data_dir: __DIR__
      end
    end
    it "throws an error if the group doesn't exist" do
      expect_raises NoSuchGroup do
        edit_access id: "5",
          path: "/doesnt/matter",
          access: "Read",
          data_dir: __DIR__
      end
    end
    it "can make Administrator read-only" do
      edit_access id: "0",
        path: "/**",
        access: "Read",
        data_dir: __DIR__
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
    describe "#edit_group_query" do
      it "throws an error when the group id is not a numeral" do
        expect_raises InvalidGroupID do
          edit_group_query id: "five",
            path: "/doesnt/matter",
            access: "Read",
            data_dir: __DIR__,
            key: "something",
            add_glob: nil,
            remove_glob: nil
        end
      end
      it "throws an error if the group doesn't exist" do
        expect_raises NoSuchGroup do
          edit_group_query id: "5",
            path: "/doesnt/matter",
            access: "Read",
            data_dir: __DIR__,
            key: "something",
            add_glob: nil,
            remove_glob: nil
        end
      end
      it "can add a glob to a query" do
        edit_group_query id: "1000",
          path: "/**",
          access: "Create | Read | Delete",
          data_dir: __DIR__,
          key: "test-key",
          add_glob: "test-glob",
          remove_glob: nil
        test_group = Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.not_nil!
        test_group.permissions["/**"]
          .query_parameters["test-key"]?
          .should eq ["test-glob"]
      end
    end
    describe "#add_route" do
      it "can add a path to a group's #permissions values" do
        add_route id: "1000", access: "Read", path: "/some/path", data_dir: __DIR__
        test_group = Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.not_nil!
        test_group.permissions["/some/path"]?.should_not be_nil
      end
    end
    describe "#delete_group" do
      it "can remove a group" do
        delete_group id: "1000", data_dir: __DIR__
        Fixtures.new_config.groups.find { |grp| grp.id == 1000 }.should be_nil
      end
    end
  end
end
