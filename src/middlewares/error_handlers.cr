require "http"
require "json"

struct ErrorData
  include JSON::Serializable
  property type : String
  property message : String?
  property status_code : HTTP::Status?

  def initialize(@type : String,
                 @message : String?,
                 @status_code : HTTP::Status? = nil)
  end

  def self.new(error : Exception)
    if error.is_a? DppmRestApi::HTTPStatusError
      # expected error handler type
      new(
        type: error.class.to_s,
        message: error.message,
        status_code: error.status_code,
      )
    else
      # any generic exception
      new(
        type: error.class.to_s,
        message: error.message,
      )
    end
  end
end

struct ErrorResponse
  include JSON::Serializable
  property errors : Array(ErrorData)

  def initialize(@errors : Array(ErrorData))
  end

  def self.new(error : Exception)
    messages = [ErrorData.new error]
    while error = error.cause
      messages << ErrorData.new error
    end
    new messages
  end

  # Log this response using the default Kemal logger.
  #
  # TODO support custom formatting.
  def log
    errors.each do |error|
      message = String.build do |msg|
        msg << "ERROR@" << Time.utc << " type: " << error.type
        msg << "; status: " << error.status_code if error.status_code
        msg << "; message: " << error.message || "(nil)"
      end
      log message
    end
  end
end

macro initialize_error_handlers
  {% for code in HTTP::Status.constants %}
  if HTTP::Status::{{code}}.value >= 400
    Kemal.config.add_error_handler HTTP::Status::{{code.id}}.value do |context, exception|
      context.response.status_code = exception.status_code.value if exception.responds_to? :status_code
      response_data = ErrorResponse.new exception
      response_data.to_json context.response
      context.response.flush
      response_data.log
      nil
    end
  end
  {% end %}
end
