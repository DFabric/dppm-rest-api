require "./exception"

module DppmRestApi::Actions
  class ImplementationError < Exception
    def initialize(data_type, message)
      super "an implementation error occurred in #{data_type}: #{message}"
    end
  end
end
