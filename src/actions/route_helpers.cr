require "./errors/*"

module DppmRestApi::Actions
  # A series of utility functions that are useful to all of the Action blocks
  module RouteHelpers
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
      rescue ex : Actions::Exception
        raise ex
      rescue ex
        # Catch non-HTTPStatusError exceptions, and throw an InternalServerError
        # with the original error as the cause.
        raise InternalServerError.new \{{block.args[0]}}, cause: ex
      end
    end
    {% end %}

    # This method parses a boolean value from a query parameter. It returns
    # true when the query parameter contains any string *except* for `"false"`
    # or `"0"`.
    def parse_boolean_param(key : String, from context : HTTP::Server::Context) : Bool
      if param = context.params.query[key]?
        return true unless {"false", "0"}.includes? param.downcase
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
  end
end
