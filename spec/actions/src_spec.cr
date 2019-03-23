require "../spec_helper"
module DppmRestApi::Actions::Src
  describe DppmRestApi::Actions::Src do
    describe "get root path" do
      it "responds with OK" do
        get root_path
        response.status_code.should eq 200
      end
    end
    ["lib", "app"].each do |type|
      describe "get \#{root_path}/#{type}" do
        it "responds with OK" do
          get "get #{root_path}/#{type}"
          response.status_code.should eq 200
        end
      end
    end
  end
end
