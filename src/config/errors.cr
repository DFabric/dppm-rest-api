macro define_error(kind, message, *args, &block)
  class {{kind.id}} < ::Exception
    def initialize({% unless args.empty? %} {{args.splat}} {% end %})
      super {{message.id}}
    end
    {% if block %}
    {{block.body}}
    {% end %}
  end
end

define_error InvalidGroupID, "failed to convert group ID '#{id}' to an integer", id
define_error NoSuchGroup, "no group found with ID number '#{id_number}'", id_number
define_error GroupAlreadyExists, "tried to create group with ID '#{id}' which already exists", id
define_error InvalidAccessParam, "failed to parse access value '#{access}', or convert it to an integer.", access
define_error DuplicateAPIKey, <<-HERE, users
  ERROR!!!        Multiple users detected with the same API key!!       ERROR!!!
  The following users each have the same API key. Keys MUST be unique!
  #{users.map(&.to_pretty_s).join('\n')}
  You MUST fix this immediately!
  HERE
define_error RequiredArgument, "the argument '#{@arg.gsub '_', '-'}' is required!", @arg : String do
  property arg
end
define_error NoRouteMatchForThisGroup, <<-HERE, path, id
  please use add-route to add a route before editing the
  query parameters of that group. No existing permissions
  data was found for the glob #{path} for the group #{id}
  HERE
