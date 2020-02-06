require "../../src/actions"
require "../spec_helper"

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

alias QueryResponse = APIResponse(Hash(String, Hash(String, String | Int64)))

struct CleanResponse
  include JSON::Serializable
  property data : Array(String)

  def should_contain_value_matching(expr : Regex)
    data.find { |response| expr =~ response } || fail "#{expr} was not in #{data}"
  end
end

def build_test_package
  pkg = DppmRestApi::Actions::Route.prefix.new_pkg "testapp"
  pkg.build confirmation: false { }
end

describe DppmRestApi::Actions::Pkg do
  route = DppmRestApi::Actions::RelativeRoute.new "/pkg"
  test_source_package_path = route.root_path + '/' + DPPM::Prefix.default_source_name

  describe "list built packages" do
    it "responds with 401 Forbidden" do
      get test_source_package_path
      assert_unauthorized response
    end

    it "responds with an empty array" do
      SpecHelper.without_authentication! do
        get test_source_package_path
        assert_no_error in: response
        ListBuiltPkgsResponse.from_json(response.body).data.should be_empty
      end
    end

    it "responds with a recently built package (build -> list flow)" do
      SpecHelper.without_authentication! do
        post test_source_package_path + "/testapp/build"
        assert_no_error in: response
        get test_source_package_path
        assert_no_error in: response
        ListBuiltPkgsResponse.from_json(response.body)
          .data.map(&.package).should contain "testapp"
      end
    end
  end

  describe "clean unused packages" do
    it "responds with 401 Forbidden" do
      delete test_source_package_path + "/clean"
      assert_unauthorized response
    end

    it "responds that there are no packages to clean" do
      SpecHelper.without_authentication! do
        delete test_source_package_path + "/clean"
        data = DppmRestApi::Actions::ErrorResponse.from_json response.body
        error_msgs = data.errors.map &.message
        error_msgs.should contain "no packages to clean"
        response.status_code.should eq HTTP::Status::NOT_FOUND.value
      end
    end

    it "cleans a built package (build -> clean flow)" do
      SpecHelper.without_authentication! do
        build_test_package
        delete test_source_package_path + "/clean"
        assert_no_error in: response
        CleanResponse.from_json(response.body).should_contain_value_matching /^testapp_\d+\.\d+\.\d+$/
        DppmRestApi::Actions::Route.prefix.each_pkg do |pkg|
          # There shouldn't be any packages
          fail "found package #{pkg.name} after cleaning"
        end
      end
    end
  end

  describe "query" do
    it "responds with 401 Forbidden" do
      get test_source_package_path + "/package-id/query"
      assert_unauthorized response
    end

    it "responds with all configuration data for a built package (build -> query flow)" do
      SpecHelper.without_authentication! do
        build_test_package
        get test_source_package_path + "/testapp/query"
        assert_no_error in: response
        NamedTuple(data: NamedTuple(testapp: Hash(String, String | Int64 | Nil))).from_json response.body
      end
    end

    it "responds with a particular configuration key" do
      SpecHelper.without_authentication! do
        build_test_package
        get test_source_package_path + "/testapp/query?get=port&prefix=" + Fixtures::PREFIX_PATH.to_s
        assert_no_error in: response
        QueryResponse.from_json(response.body).data["testapp"]["port"].should eq 1
      end
    end
  end

  describe "delete a package" do
    it "responds with 401 Forbidden" do
      delete test_source_package_path + "/package-id/delete"
      assert_unauthorized response
    end

    it "successfully deletes a package (build -> delete flow)" do
      build_test_package
      SpecHelper.without_authentication! do
        build_test_package
        delete test_source_package_path + "/testapp/delete"
        assert_no_error in: response
        DeleteResponse.from_json(response.body).should_be_successful_for "testapp"
      end
    end
  end

  describe "build a package" do
    it "responds with 401 Forbidden" do
      post test_source_package_path + "/some-package/build"
      assert_unauthorized response
    end

    it "builds a test package" do
      SpecHelper.without_authentication! do
        post test_source_package_path + "/testapp/build"
        assert_no_error in: response
        BuildResponse.from_json(response.body).should_be_successful_for "testapp"
      end
    end

    it "responds with Bad Request when given an invalid package name" do
      SpecHelper.without_authentication! do
        post test_source_package_path + "/$(echo all your base are belong to us!)/build"
        response.status_code.should eq HTTP::Status::BAD_REQUEST.value
      end
    end
  end
end
