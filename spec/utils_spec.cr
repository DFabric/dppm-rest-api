require "./spec_helper"

describe "#deny_access!" do
  it "denies access" do
    backing_io, ctx = new_test_context
    deny_access! to: ctx
    ctx.response.status_code.should eq 401
    backing_io.rewind.gets_to_end.ends_with?("Forbidden." + CRLF).should be_true
  end
end
