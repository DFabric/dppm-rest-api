require "../spec_helper"

module DppmRestApi::Actions::Src
  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      it "responds with 401 Forbidden" do
        get root_path
        response.status_code.should eq 401
      end
    end
    ["lib", "app"].each do |type|
      describe "get \#{root_path}/#{type}" do
        it "responds with 401 Forbidden" do
          get "get #{root_path}/#{type}"
          response.status_code.should eq 401
        end
      end
    end
  end
end
