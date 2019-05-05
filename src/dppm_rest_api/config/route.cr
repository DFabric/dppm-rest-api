require "./access"

module DppmRestApi
  # Matches a request to a series of globs loaded from a config file.
  struct Route
    include JSON::Serializable

    # The permission/access level for this route
    property permissions : Access

    property query_parameters : Hash(String, Array(String)) do
      {} of String => Array(String)
    end

    def initialize(@permissions, @query_parameters); end

    # Returns true if this Route matches the given query parameters. Does not
    # imply a matching access.
    def match?(parameters : HTTP::Params)
      return true unless query_parameters.any? do |key, _|
                           parameters.has_key? key
                         end
      !!parameters.find do |key, value|
        if glob = query_parameters[key]?.try &.first?
          File.match? glob, value
        end
      end
    end
  end
end
