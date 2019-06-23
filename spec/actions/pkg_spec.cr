require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Pkg
  struct ListBuiltPkgsResponse
    include JSON::Serializable
    property data : Array(String)

    def should_be_empty
      data.empty?.should be_true
      self
    end
  end

  abstract struct StatusResponse
    struct StatusResponseInternal
      include JSON::Serializable
      property status : String
    end

    include JSON::Serializable
    property data : StatusResponseInternal

    abstract def should_be_successful_for(package)
  end

  struct BuildResponse < StatusResponse
    def should_be_successful_for(package)
      data.status.should match /^built package #{package}:(.+) successfully$/
    end
  end

  struct DeleteResponse < StatusResponse
    def should_be_successful_for(package)
      data.status.should eq "successfully deleted '#{package}'"
    end
  end

  struct QueryResponse
    include JSON::Serializable
    property data : Hash(String, Hash(String, String | Int64))
  end

  describe DppmRestApi::Actions::Pkg do
    describe "list built packages" do
      it "responds with 401 Forbidden" do
        get fmt_route nil
        assert_unauthorized response
      end
      it "responds with an empty array" do
        SpecHelper.without_authentication! do
          get fmt_route "?prefix=" + Fixtures::PREFIX_PATH
          response.status_code.should eq HTTP::Status::OK.value
          ListBuiltPkgsResponse.from_json(response.body).should_be_empty
        end
      end
    end
    describe "clear unused packages (#{fmt_route "/clean"})" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/clean"
        assert_unauthorized response
      end
      it "responds that there are no packages to clean" do
        SpecHelper.without_authentication! do
          delete fmt_route("/clean?prefix=" + Fixtures::PREFIX_PATH)
          # response.status_code.should eq 404
          data = ErrorResponse.from_json response.body
          error_msgs = data.errors.map &.message
          error_msgs.should contain "no packages to clean"
          error_msgs.should_not contain "received empty set from Prefix#clean_unused_packages; please report this strange bug"
        end
      end
    end
    describe "get /:id/query" do
      it "responds with 401 Forbidden" do
        get fmt_route "/package-id/query"
        assert_unauthorized response
      end
      it "responds with all configuration data for a built package (build -> query flow)" do
        SpecHelper.without_authentication! do
          post fmt_route "/dppm/build?prefix=" + Fixtures::PREFIX_PATH
          if response.status_code != HTTP::Status::OK.value
            fail "building package 'dppm' (to test querying its configuration) due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          get fmt_route "/dppm/query?prefix=" + Fixtures::PREFIX_PATH
          response.status_code.should eq HTTP::Status::OK.value
          response.body.should eq %<{"data":{"dppm":{"port":8994,"host":"[::1]"}}}>
        end
      end
      it "responds with a particular configuration key" do
        SpecHelper.without_authentication! do
          post fmt_route "/dppm/build?prefix=" + Fixtures::PREFIX_PATH
          if response.status_code != HTTP::Status::OK.value
            fail "building package 'dppm' (to test querying its configuration) due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          get fmt_route "/dppm/query?get=port&prefix=" + Fixtures::PREFIX_PATH
          response.status_code.should eq HTTP::Status::OK.value
          QueryResponse.from_json(response.body).data["dppm"]["port"].should eq 8994
        end
      end
    end
    describe "delete a package (/:id/delete)" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/package-id/delete"
        assert_unauthorized response
      end
      it "successfully deletes a package (build -> delete flow)" do
        SpecHelper.without_authentication! do
          post fmt_route "/dppm/build?prefix=" + Fixtures::PREFIX_PATH
          if response.status_code != HTTP::Status::OK.value
            fail "building package 'dppm' (to test deleting it) due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          delete fmt_route "/dppm/delete?prefix=" + Fixtures::PREFIX_PATH
          if response.status_code != HTTP::Status::OK.value
            fail "deleting package 'dppm' due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          DeleteResponse.from_json(response.body).should_be_successful_for "dppm"
        end
      end
    end
  end
  describe "post fmt_route \"/:id/build\"" do
    it "responds with 401 Forbidden" do
      post fmt_route "/some-package/build"
      assert_unauthorized response
    end
    it "builds a test package" do
      SpecHelper.without_authentication! do
        post fmt_route "/dppm/build?prefix=" + Fixtures::PREFIX_PATH
        if response.status_code != HTTP::Status::OK.value
          puts ErrorResponse.from_json(response.body).errors
          fail "POST '/dppm/build?prefix=" + Fixtures::PREFIX_PATH + "' received status code " + HTTP::Status.new(response.status_code).to_s
        end
        BuildResponse.from_json(response.body).should_be_successful_for "dppm"
      end
    end
  end
end
