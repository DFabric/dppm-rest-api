require "../src/actions"
require "./spec_helper"

describe DppmRestApi::Actions do
  pending "has access" do
    # @@access_filter = ->(_context : HTTP::Server::Context, _permission : DppmRestApi::Access) { true }
    get "/"
    assert_no_error in: response
  end
end
