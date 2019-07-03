require "./http_status_errors"

module DppmRestApi::Actions
  class BooleanParamHasValue < BadRequest
    def initialize(context : HTTP::Server::Context, param : String, value : String)
      super context, "\
            boolean parameters must be specified only by whether or not they are \
            present. &#{param}=#{value} is incorrect, please use &#{param} for true \
            or do not specify it for false."
    end
  end
end
