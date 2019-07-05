require "../spec_helper"

module DppmRestApi::Actions::User
  struct UserAddResponse
    include JSON::Serializable
    getter name : String
    getter group_ids : Set(Int32)
  end

  describe "POST #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      post fmt_route nil
      assert_unauthorized response
    end
    it "adds a user" do
      SpecHelper.without_authentication! do
        post fmt_route(nil), body: Fixtures::USER_BODY.to_json
        if response.status_code == HTTP::Status::OK.value
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
          if config_user = DppmRestApi.permissions_config.users.find { |u| u.name == user.name }
            user.group_ids.should eq config_user.group_ids
            fail "key fails to authenticate user" unless config_user.api_key_hash.verify key
          else
            fail "did not find user in permissions config"
          end
        else
          puts ErrorResponse.from_json response.body
          fail "received error response from 'POST #{fmt_route nil}' with status code #{HTTP::Status.new response.status_code}"
        end
      end
    end
  end
  describe "DELETE #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      delete fmt_route nil
      assert_unauthorized response
    end
  end
  describe "GET #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      get fmt_route nil
      assert_unauthorized response
    end
  end
end
