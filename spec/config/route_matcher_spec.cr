require "../spec_helper"

TEST_PARAMS = {"namespace" => ["test-namespace"]}
describe DppmRestApi::Config::Route do
  it "works as expected" do
    test_rte = DppmRestApi::Config::Route.new(DppmRestApi::Access::Create, TEST_PARAMS)
    test_rte.match?(HTTP::Params.new TEST_PARAMS).should be_true
    test_rte.permissions.create?.should be_true
  end
end
