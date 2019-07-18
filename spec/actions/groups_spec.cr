require "../spec_helper"

module DppmRestApi::Actions::Groups
  describe "post #{self}" do
    it "responds with 401 Forbidden" do
      post fmt_route
      assert_unauthorized response
    end
  end
  describe "put #{fmt_route "/:id/route"}" do
    it "responds with 401 Forbidden" do
      put fmt_route "/some%2Froute/route"
      assert_unauthorized response
    end
  end
  describe "put #{fmt_route "/:id/param"}" do
    it "responds with 401 Forbidden" do
      put fmt_route "/some-param/param"
      assert_unauthorized response
    end
  end
  describe "delete #{fmt_route "/:id/route"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/some%2Froute/route"
      assert_unauthorized response
    end
  end
  describe "delete #{fmt_route "/:id/param"}" do
    it "responds with 401 Forbidden" do
      delete fmt_route "/some-param/param"
      assert_unauthorized response
    end
  end
end
