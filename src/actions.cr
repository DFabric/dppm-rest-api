require "kemal"

macro fmt_route(route = "", namespace = false)
  {{ "/" + @type.stringify
       .downcase
       .gsub(/^DppmRestApi::Actions::/, "")
       .gsub(/::/, "/") }} {% if namespace %} + "/:namespace" {% end %} + ( {{route}} || "")
end

# the "last" or -1st block argument is selected because context is always the
# argument -- either the only or the second of two
{% for method in %w(get post put delete ws options) %}
macro relative_{{method.id}}(route, &block)
  {{method.id}} fmt_route(\{{route}}) do |\{{block.args.splat}}|
    namespace = \{{block.args[-1]}}.params.query["namespace"]? || DPPM::Prefix.default_group
    \{{block.body}}
  end
end
{% end %}

require "./access"
require "./actions/*"
require "./errors/*"

module DppmRestApi::Actions
  DEFAULT_DATA_DIR = "./data/"
  API_DOCUMENT     = DEFAULT_DATA_DIR + "api-options.json"

  include Pkg
  include App
  include Service
  include Src

  before_all do |ctx|
    ctx.response.content_type = "application/json"
  end

  relative_options "/api" do |context|
    File.open API_DOCUMENT do |file|
      IO.copy file, context.response
    end
  end

  def self.has_access?(context : HTTP::Server::Context, access : Access) : Bool
    access_filter.call context, access
  end

  protected class_property access_filter : Proc(HTTP::Server::Context, Access, Bool) = ->(context : HTTP::Server::Context, access : Access) { false }
end
