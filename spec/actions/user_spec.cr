require "../spec_helper"

struct UserAddResponse
  include JSON::Serializable
  getter name : String
  getter group_ids : Set(Int32)
end

struct UserDeleteResponse
  struct Status
    include JSON::Serializable
    getter status : String
  end

  include JSON::Serializable
  getter data : Status
end

struct UserGetResponse
  struct Data
    include JSON::Serializable
    getter users : Array(User)

    struct User
      include JSON::Serializable
      getter name : String
      @[JSON::Field(ignore: true)]
      getter config_user : DppmRestApi::Config::User do
        DppmRestApi.permissions_config.users.find do |user|
          user.name == name
        end || fail "no user found in #{DppmRestApi.permissions_config.users} with the name #{name}"
      end

      def which_should_be_in_groups(groups : Enumerable(Int32))
        groups.each do |group|
          unless config_user.group_ids.includes? group
            fail "user #{config_user} is not a member of the group #{group}"
          end
        end
      end
    end
  end

  include JSON::Serializable
  getter data : Data

  def should_contain_user_named(name : String)
    user = data.users.find &.name.== name
    fail "user named #{name} was not found in #{data.users}" if user.nil?
    user
  end
end

describe DppmRestApi::Actions::User do
  route = DppmRestApi::Actions::RelativeRoute.new "/user"

  describe "POST #{route.root_path}" do
    it "responds with 401 Forbidden" do
      post route.root_path
      assert_unauthorized response
    end

    it "adds a user" do
      SpecHelper.without_authentication! do
        post route.root_path, body: Fixtures::USER_BODY.to_json
        assert_no_error in: response
        key, user = nil, nil
        json = JSON::PullParser.new response.body
        json.read_object do |json_key|
          fail "received unexpected top-level key #{json_key}" if json_key != "data"
          json.read_object do |data_key|
            case data_key
            when "AccessKey"             then key = json.read_string
            when "SuccessfullyAddedUser" then user = UserAddResponse.new json
            else
              fail "received unexpected response key #{json_key}"
            end
          end
        end
        fail "response did not contain AccessKey" if key.nil?
        fail "response did not contain SuccessfullyAddedUser" if user.nil?
        user.name.should eq "Mock user"
        if config_user = DppmRestApi.permissions_config.users.find &.name.== user.name
          user.group_ids.should eq config_user.group_ids
          fail "key fails to authenticate user" unless config_user.api_key_hash.verify key
        else
          fail "did not find user in permissions config"
        end
      end
    end
  end

  describe "DELETE #{route.root_path}" do
    it "responds with 401 Forbidden" do
      delete route.root_path + '/' + UUID.random.to_s
      assert_unauthorized response
    end

    it "successfully deletes a user from the configuration" do
      SpecHelper.without_authentication! do
        user_id = DppmRestApi.permissions_config.users.find { |user| user.name == "Jim Oliver" }.try &.id
        delete route.root_path + '/' + user_id.to_s
        assert_no_error in: response
        UserDeleteResponse.from_json(response.body).data.status.should eq "success"
        DppmRestApi.permissions_config.users.find { |user| user.name == "Jim Oliver" }.should be_nil
      end
    end
  end

  describe "GET #{route.root_path}" do
    it "responds with 401 Forbidden" do
      get route.root_path
      assert_unauthorized response
    end

    it "lists the currently present users" do
      SpecHelper.without_authentication! do
        get route.root_path
        assert_no_error in: response
        data = UserGetResponse.from_json(response.body)
        data.should_contain_user_named("Administrator").which_should_be_in_groups({0})
        data.should_contain_user_named("Jim Oliver").which_should_be_in_groups({499, 1000})
      end
    end
  end

  describe "GET #{route.root_path + "/me"}" do
    it "responds with 401 Forbidden" do
      get route.root_path + "/me"
      assert_unauthorized response
    end

    it "returns information about the user defined in the JWT" do
      jim = DppmRestApi.permissions_config.users.find &.name.starts_with? "Jim"
      fail "didn't find 'Jim' in config" if jim.nil?
      jwt = DppmRestApi::Actions.encode jim
      headers = HTTP::Headers.new
      headers.add "X-Token", jwt
      get route.root_path + "/me", headers
      assert_no_error in: response
      data = JSON.parse(response.body)["data"]
      data["currentUser"]["name"].as_s.should eq "Jim Oliver"
      data["currentUser"]["group_ids"].as_a.should eq [499, 1000]
    end
  end
end
