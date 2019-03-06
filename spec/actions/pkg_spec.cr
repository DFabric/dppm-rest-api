module DppmRestApi::Actions::Pkg
  describe DppmRestApi::Actions::Pkg do
    describe "get ALL_PKGS" do
      it "responds with 200 OK" do
        get ALL_PKGS
        response.status_code.should eq 200
      end
    end
    describe "delete ALL_PKGS" do
      it "responds with 200 OK" do
        delete ALL_PKGS
        response.status_code.should eq 200
      end
    end
    describe "get ONE_PKG" do
      it "responds with 200 OK" do
        get ONE_PKG
        response.status_code.should eq 200
      end
    end
    describe "delete ONE_PKG" do
      it "responds with 200 OK" do
        delete ONE_PKG
        response.status_code.should eq 200
      end
    end
  end
  module Build
    describe Build do
      describe "post \#{root_path}/:package" do
        post root_path + "/:package"
        response.status_code.should eq 200
      end
    end
  end
end
