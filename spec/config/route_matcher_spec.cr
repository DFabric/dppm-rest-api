require "../spec_helper"

TestParams = {"namespace" => ["test-namespace"]}
describe DppmRestApi::Config::Route do
  it "works as expected" do
    test_rte = DppmRestApi::Config::Route.new(DppmRestApi::Access::Create, TestParams)
    test_rte.match?(HTTP::Params.new TestParams).should be_true
    test_rte.permissions.create?.should be_true
  end
end
