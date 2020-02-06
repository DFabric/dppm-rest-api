require "./errors/*"

# A series of route utilities functions that are useful to all of the Action blocks.
module DppmRestApi::Actions::Route
  class_property prefix : DPPM::Prefix { raise "No prefix set" }

  # Get a prefix from a context, which has a source name.
  def self.get_prefix_with_source_name(context : HTTP::Server::Context) : DPPM::Prefix
    DPPM::Prefix.new(
      path: prefix.path.to_s,
      group: prefix.group,
      source_name: URI.decode(context.params.url["source_name"]),
      source_path: prefix.source_path
    )
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

  private def build_json(response : IO, & : JSON::Builder ->)
    JSON.build response do |json|
      json.object do
        json.field("data") { yield json }
      end
    end
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
  # build_json_object do
  #   raise InternalServerError.new "Oh no!"
  # end
  # ```
  # ...would result in the following response body...
  # ```
  # {"data":{"errors": [{"type": "InternalServerError", "status_code": 500, "message": "oh no!"}]}
  # ```
  # ...which is not valid JSON due to the unclosed object written at the beginning.
  def build_json_object(response : IO, & : JSON::Builder ->)
    build_json response do |json|
      json.object { yield json }
    end
  end

  # Like `#build_json_object`, but builds an array instead of an object
  def build_json_array(response : IO, & : JSON::Builder ->)
    build_json response do |json|
      json.array { yield json }
    end
  end
end
