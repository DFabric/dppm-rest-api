require "../spec_helper"

module DppmRestApi::Actions::Src
  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      pending "responds with 401 Forbidden" do
        get fmt_route
        response.status_code.should eq 401
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
