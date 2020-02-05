require "../src/actions"
require "./spec_helper"

describe DppmRestApi::Actions do
  route = DppmRestApi::Actions::RelativeRoute.new "/actions"

  pending "has access" do
    # @@access_filter = ->(_context : HTTP::Server::Context, _permission : DppmRestApi::Access) { true }
    get route.root_path
    assert_no_error in: response
  end
end
