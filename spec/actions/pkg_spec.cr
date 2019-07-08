require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Pkg
  struct ListBuiltPkgsResponse
    record ListedPackageData, package : String, version : String do
      include JSON::Serializable
    end
    include JSON::Serializable
    getter data : Array(ListedPackageData)
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

  struct CleanResponse
    include JSON::Serializable
    property data : Array(String)

    def should_contain_value_matching(expr : Regex)
      data.find { |response| expr =~ response } || fail "#{expr} was not in #{data}"
    end
  end

  def build_test_package
    pkg = Actions.prefix.new_pkg "testapp"
    pkg.build confirmation: false { }
  end

  describe DppmRestApi::Actions::Pkg do
    describe "list built packages" do
      it "responds with 401 Forbidden" do
        get fmt_route '/' + DPPM::Prefix.default_source_name
        assert_unauthorized response
      end
      it "responds with an empty array" do
        SpecHelper.without_authentication! do
          get fmt_route '/' + DPPM::Prefix.default_source_name
          response.status_code.should eq HTTP::Status::OK.value
          ListBuiltPkgsResponse.from_json(response.body).data.should be_empty
        end
      end
      it "responds with a recently built package (build -> list flow)" do
        SpecHelper.without_authentication! do
          post fmt_route "/#{DPPM::Prefix.default_source_name}/testapp/build"
          if response.status_code != HTTP::Status::OK.value
            fail "building package 'testapp' (to test listing packages) due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          get fmt_route '/' + DPPM::Prefix.default_source_name
          ListBuiltPkgsResponse.from_json(response.body)
            .data.map(&.package).should contain "testapp"
        end
      end
    end
    describe "clean unused packages" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/#{DPPM::Prefix.default_source_name}/clean"
        assert_unauthorized response
      end
      it "responds that there are no packages to clean" do
        SpecHelper.without_authentication! do
          delete fmt_route "/#{DPPM::Prefix.default_source_name}/clean"
          # response.status_code.should eq 404
          data = ErrorResponse.from_json response.body
          error_msgs = data.errors.map &.message
          error_msgs.should contain "no packages to clean"
          error_msgs.should_not contain "received empty set from Prefix#clean_unused_packages; please report this strange bug"
        end
      end
      it "cleans a built package (build -> clean flow)" do
        SpecHelper.without_authentication! do
          build_test_package
          delete fmt_route "/#{DPPM::Prefix.default_source_name}/clean"
          CleanResponse.from_json(response.body).should_contain_value_matching /^testapp_\d+\.\d+\.\d+$/
          response.status_code.should eq HTTP::Status::OK.value
          Actions.prefix.each_pkg do |pkg|
            # There shouldn't be any packages
            fail "found package #{pkg.name} after cleaning"
          end
        end
      end
    end
    describe "query" do
      it "responds with 401 Forbidden" do
        get fmt_route "/#{DPPM::Prefix.default_source_name}/package-id/query"
        assert_unauthorized response
      end
      it "responds with all configuration data for a built package (build -> query flow)" do
        SpecHelper.without_authentication! do
          build_test_package
          get fmt_route "/#{DPPM::Prefix.default_source_name}/testapp/query"
          response.status_code.should eq HTTP::Status::OK.value
          response.body.should eq %<{"data":{"testapp":{"port":1,"host":"[::1]"}}}>
        end
      end
      it "responds with a particular configuration key" do
        SpecHelper.without_authentication! do
          build_test_package
          get fmt_route "/#{DPPM::Prefix.default_source_name}/testapp/query?get=port&prefix=" + Fixtures::PREFIX_PATH.to_s
          response.status_code.should eq HTTP::Status::OK.value
          QueryResponse.from_json(response.body).data["testapp"]["port"].should eq 1
        end
      end
    end
    describe "delete a package" do
      it "responds with 401 Forbidden" do
        delete fmt_route "/#{DPPM::Prefix.default_source_name}/package-id/delete"
        assert_unauthorized response
      end
      it "successfully deletes a package (build -> delete flow)" do
        SpecHelper.without_authentication! do
          build_test_package
          delete fmt_route "/#{DPPM::Prefix.default_source_name}/testapp/delete"
          if response.status_code != HTTP::Status::OK.value
            fail "deleting package 'testapp' due to " + ErrorResponse.from_json(response.body).errors.to_s
          end
          DeleteResponse.from_json(response.body).should_be_successful_for "testapp"
        end
      end
    end
  end
  describe "build a package" do
    it "responds with 401 Forbidden" do
      post fmt_route "/#{DPPM::Prefix.default_source_name}/some-package/build"
      assert_unauthorized response
    end
    it "builds a test package" do
      SpecHelper.without_authentication! do
        post fmt_route "/#{DPPM::Prefix.default_source_name}/testapp/build"
        if response.status_code != HTTP::Status::OK.value
          fail "POST '/#{DPPM::Prefix.default_source_name}/testapp/build' received status code " + HTTP::Status.new(response.status_code).to_s
        end
        BuildResponse.from_json(response.body).should_be_successful_for "testapp"
      end
    end
    it "responds with Bad Request when given an invalid package name" do
      SpecHelper.without_authentication! do
        post fmt_route "/#{DPPM::Prefix.default_source_name}/$(echo all your base are belong to us!)/build"
        response.status_code.should eq HTTP::Status::BAD_REQUEST.value
      end
    end
  end
end
