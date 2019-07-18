require "kemal"
require "./access"
require "./actions/route_helpers"
require "./actions/*"

module DppmRestApi::Actions
  extend self
  include RouteHelpers

  DEFAULT_DATA_DIR = "./data/"
  API_DOCUMENT     = DEFAULT_DATA_DIR + "api-options.json"
  alias ConfigKeyError = DPPM::Prefix::Base::ConfigKeyError

  include Pkg
  include App
  include Service
  include Src
  include User
  include Groups

  before_all do |context|
    context.response.content_type = "application/json"
  end

  relative_options "/api" do |context|
    File.open API_DOCUMENT do |file|
      IO.copy file, context.response
    end
  end

  def has_access?(context : HTTP::Server::Context, access : Access) : Bool
    access_filter.call context, access
  end

  class_property prefix : DPPM::Prefix { raise "no prefix set" }
  protected class_property access_filter : Proc(HTTP::Server::Context, Access, Bool) = ->(context : HTTP::Server::Context, access : Access) { false }
end
