require "../spec_helper"

module DppmRestApi::Actions::Pkg
  describe DppmRestApi::Actions::Pkg do
    describe "get ALL_PKGS" do
      it "responds with 401 Forbidden" do
        get ALL_PKGS
        response.status_code.should eq 401
      end
    end
    describe "delete ALL_PKGS" do
      it "responds with 401 Forbidden" do
        delete ALL_PKGS
        response.status_code.should eq 401
      end
    end
    describe "get ONE_PKG" do
      it "responds with 401 Forbidden" do
        get ONE_PKG
        response.status_code.should eq 401
      end
    end
    describe "delete ONE_PKG" do
      it "responds with 401 Forbidden" do
        delete ONE_PKG
        response.status_code.should eq 401
      end
    end
  end

  module Build
    describe Build do
      describe "post root_path \"/:package\"" do
        it "responds with 401 Forbidden" do
          post root_path "/some-package"
          response.status_code.should eq 401
        end
      end
    end
  end
end
