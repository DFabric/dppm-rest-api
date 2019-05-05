describe DppmRestApi::Group do
  describe "super user" do
    it "has access to everything" do
      group = DppmRestApi.config.file.group(named: "super user").not_nil!
      group.can_access?(
        "/literally/any/path",
        HTTP::Params.new({"and" => ["query", "parameters"]}),
        DppmRestApi::Access::Delete).should be_true
      group.permissions.each do |glob, rte|
        glob.empty?.should be_false
        rte.permissions.should eq DppmRestApi::Access.super_user
      end
    end
  end
end
