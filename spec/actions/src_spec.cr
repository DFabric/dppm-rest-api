require "../spec_helper"

module DppmRestApi::Actions::Src
  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      it "responds with 401 Forbidden" do
        get root_path
        response.status_code.should eq 401
      end
    end
    # {% for src_type in ["lib", "app"] %}
    # describe "get #{root_path {{src_type}}}" do
    #   it "responds with 401 Forbidden" do
    #     get root_path {{src_type}}
    #     response.status_code.should eq 401
    #   end
    # end
    # {% end %}
  end
end
