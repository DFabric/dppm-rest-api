module DppmRestApi::Actions
  class ConfigKeyNotFound < NotFound
    def self.new(context : HTTP::Server::Context,
                 key : String,
                 package_name : String,
                 cause : Exception? = nil)
      new context, "config key #{key} not found in #{package_name}'s configuration", cause
    end
  end
end
