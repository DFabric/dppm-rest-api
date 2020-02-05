require "../../src/actions"
require "../spec_helper"

struct SrcListResponse
  struct Data
    include JSON::Serializable
    property sources : Array(Source)

    struct Source
      include JSON::Serializable
      property name : String
    end

    def should_have_source_named(name : String) : self
      sources.map(&.name).should contain name
      self
    end

    def should_not_have_source_named(name : String) : self
      sources.map(&.name).should_not contain name
      self
    end
  end

  include JSON::Serializable
  property data : Data
end

describe DppmRestApi::Actions::Src do
  route = DppmRestApi::Actions::RelativeRoute.new "/src"

  describe "get root path" do
    it "responds with 401 Forbidden" do
      get route.root_path
      assert_unauthorized response
    end

    it "responds with a list of sources" do
      SpecHelper.without_authentication! do
        get route.root_path
        assert_no_error in: response
        SrcListResponse
          .from_json(response.body)
          .data
          .should_have_source_named "Test App"
      end
    end

    it "respects filters" do
      SpecHelper.without_authentication! do
        get route.root_path + "?filter=package=testapp=libfake"
        assert_no_error in: response
        SrcListResponse
          .from_json(response.body)
          .data
          .should_have_source_named("Test App")
          .should_have_source_named("Fake library")
        get route.root_path + "?filter=package=libfake"
        assert_no_error in: response
        SrcListResponse
          .from_json(response.body)
          .data
          .should_have_source_named("Fake library")
          .should_not_have_source_named("Test App")
      end
    end
  end
end
