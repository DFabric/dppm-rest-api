require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Src
  struct ListSources
    record Source, source_name : String, url : String do
      include JSON::Serializable
    end
    include JSON::Serializable
    getter data : Array(Source)
  end

  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      it "responds with 401 Forbidden" do
        get fmt_route
        assert_unauthorized response
      end

      it "lists available sources" do
        SpecHelper.without_authentication! do
          get fmt_route
          response.status_code.should eq HTTP::Status::OK.value
          ListSources.from_json(response.body).data.should_not be_empty
        end
      end
    end
  end
end
