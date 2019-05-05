require "./spec_helper"

describe "Actions.throw_error" do
  it "expands as expected" do
    backing_io, context = new_test_context
    app_name = "test.app.name"
    DppmRestApi::Actions.throw_error context, "no config with app named '#{app_name}' found", status_code: 404
    context.response.status_code.should eq 404
    backing_io.rewind
      .gets_to_end
      .ends_with?("no config with app named 'test.app.name' found\n" + CRLF)
      .should be_true
  end
end
