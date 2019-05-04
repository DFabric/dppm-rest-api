require "./exception"

module DppmRestApi
  class ImplementationError < Exception
    def initialize(data_type, message)
      super "an implementation error occurred in #{data_type}: #{message}"
    end
  end
end
