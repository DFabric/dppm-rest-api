module DppmRestApi::Actions
  class InvalidFilter < BadRequest
    def initialize(context, cause : Exception? = nil)
      super context, <<-HERE, cause
      A filter MUST contain at least two equals-separated values,
      like filter=somekey=value. You can specify more than one option, like
      filter=somekey=value1=value2=value3, but there must be at least a key
      and a value.
      HERE
    end
  end
end
