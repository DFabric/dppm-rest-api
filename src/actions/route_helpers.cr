require "./errors/*"

# A series of route utilities functions that are useful to all of the Action blocks.
module DppmRestApi::Actions::RouteHelpers
  macro included
  ROOT_PATH = {{ "/" + @type.stringify.downcase.split("::").last }}

  # Transform a relative route to an absolute one from the `ROOT_PATH`.
  def fmt_route(relative_route : String? = nil, namespace : Bool = false)
    ROOT_PATH + (namespace ? "/:namespace" : "") + relative_route.to_s
  end

  {% for method in %w(get post put delete ws options) %}
  # Perform a relative {{method.id}} from the `ROOT_PATH`.
  def relative_{{method.id}}(route : String? = nil, &block : HTTP::Server::Context ->)
    {{method.id}} fmt_route(route) do |context|
      #namespace = context.params.query["namespace"]? || DPPM::Prefix.default_group
      block.call context
    rescue ex : Actions::Exception
      raise ex
    rescue ex
      # Catch non-HTTPStatusError exceptions, and throw an InternalServerError
      # with the original error as the cause.
      raise InternalServerError.new context, cause: ex
    end
  end
  {% end %}
  end

  # This method parses a boolean value from a query parameter. It returns
  # true when the query parameter is specified, but empty; false when the
  # parameter is not specified (null); and otherwise raises a BadRequest
  # exception.
  def parse_boolean_param(key : String, from context : HTTP::Server::Context) : Bool
    context.params.query[key]?.try do |value|
      return true if value.empty?
      raise BooleanParamHasValue.new context, key, value
    end
    false
  end

  # Build JSON directly to the HTTP response IO. This yields inside of an
  # object labelled "data", like
  # ```
  # {"data": {"whatever": "you build"}}
  # ```
  # Since it's in an object, one needs to use `JSON::Builder#field` at the
  # top-level within the block.
  #
  # NOTE: One must also ensure that the block does not raise an exception --
  # this would result in invalid JSON being output as the response body. For
  # example...
  # ```
  # build_json do
  #   raise InternalServerError.new "oh no!"
  # end
  # ```
  # ...would result in the following response body...
  # ```
  # {"data":{"errors": [{"type": "InternalServerError", "status_code": 500, "message": "oh no!"}]}
  # ```
  # ...which is not valid JSON due to the unclosed object written at the beginning.
  def build_json(response : IO)
    JSON.build response do |json|
      json.object do
        json.field("data") { json.object { yield json } }
      end
    end
  end

  # Get a prefix from a context, which has a source name.
  def get_prefix_with_source_name(context : HTTP::Server::Context) : DPPM::Prefix
    DPPM::Prefix.new(
      path: Actions.prefix.path.to_s,
      group: Actions.prefix.group,
      source_name: URI.unescape(context.params.url["source_name"]),
      source_path: Actions.prefix.source_path
    ).tap &.ensure_pkg_dir
  end
end
