require "../../src/actions"
require "../spec_helper"

module DppmRestApi::Actions::Src
  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      it "responds with 401 Forbidden" do
        get fmt_route
        assert_unauthorized response
      end
    end
    # {% for src_type in ["lib", "app"] %}
    # describe "get #{fmt_route {{src_type}}}" do
    #   it "responds with 401 Forbidden" do
    #     get fmt_route {{src_type}}
    #     response.status_code.should eq 401
    #   end
    # end
    # {% end %}
  end
end
