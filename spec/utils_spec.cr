require "./spec_helper"

CRLF = "\r\n"

describe "#deny_access!" do
  it "denies access" do
    backing_io, ctx = new_test_context
    deny_access! to: ctx
    ctx.response.status_code.should eq 401
    backing_io.rewind.gets_to_end.ends_with?("Forbidden." + CRLF).should be_true
  end
end

describe :throw do
  it "expands as expected" do
    backing_io, context = new_test_context
    app_name = "test.app.name"
    throw "no config with app named '%s' found", app_name, status_code: 404
    context.response.status_code.should eq 404
    backing_io.rewind
      .gets_to_end
      .ends_with?("no config with app named 'test.app.name' found\n" + CRLF)
      .should be_true
  end
end
