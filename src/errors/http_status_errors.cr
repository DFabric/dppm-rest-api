require "http"
require "./exception"

module DppmRestApi
  abstract class HTTPStatusError < Exception
    abstract def status_code
  end

  {% for status_code in HTTP::Status.constants %}
  {% type_name = status_code.stringify.downcase.camelcase.id %}
  # An exception for the {{status_code}} status
  class {{type_name.id}} < HTTPStatusError
    STATUS_CODE = HTTP::Status::{{status_code}}

    def status_code
      STATUS_CODE
    end

    getter context : HTTP::Server::Context
    def initialize(@context : HTTP::Server::Context, message : String? = nil, cause : ::Exception? = nil)
      @context.response.status_code = self.status_code.value
      message ||= HTTP::Status::{{status_code}}.description || {{status_code.stringify.capitalize.gsub /_/, " "}}
      super message, cause
    end
  end
  {% end %}
end
