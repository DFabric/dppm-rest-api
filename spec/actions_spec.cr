require "../src/actions"
require "./spec_helper"

module DppmRestApi::Actions
  describe DppmRestApi::Actions do
    pending "has access" do
      # @@access_filter = ->(_context : HTTP::Server::Context, _permission : DppmRestApi::Access) { true }
      get fmt_route "/api"
      response.status_code.should eq 200
    end
  end
end
