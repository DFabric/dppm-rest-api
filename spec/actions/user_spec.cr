module DppmRestApi::Actions::User
  describe "POST #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      post fmt_route nil
      assert_unauthorized response
    end
  end
  describe "DELETE #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      delete fmt_route nil
      assert_unauthorized response
    end
  end
  describe "GET #{fmt_route nil}" do
    it "responds with 401 Forbidden" do
      get fmt_route nil
      assert_unauthorized response
    end
  end
end
