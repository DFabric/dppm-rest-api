require "kemal"
require "kemal_jwt_auth"
require "./user"
require "./route"

# Render the given data as JSON to the local `context` variable.
macro render_data(data)
  context.response.content_type = "application/json"
  IO.copy {{data.id}}, context.response
end

def deny_access!(to context)
  context.response.status_code = 401
  context.response.write "Forbidden.".to_slice
  context.response.flush
  context
end

private def deserialize(groups ambiguously_typed : Bool | Int32 | String?)
  if (groups = ambiguously_typed).is_a? String
    groups.split(",").map &.to_i
  end
end

# returns true if the given user has access to the given context with the given
# permission type
def has_access?(context : HTTP::Server::Context, permission : DppmRestApi::Access)
  if user = context.current_user?.try { |user| DppmRestApi::User.from_h hash: user }
    return true if user.find_group? do |group|
                     group.can_access?(
                       context.request.path,
                       context.request.query_params,
                       permission
                     )
                   end
  end
  false
end

alias JWTCompatibleHash = Hash(String, String | Int32 | Bool?)

macro fmt_route(route = "", namespace = false)
  {{ "/" + @type.stringify
       .downcase
       .gsub(/^DppmRestApi::Actions::/, "")
       .gsub(/::/, "/") }} {% if namespace %} + "/:namespace" {% end %} + ( {{route}} || "")
end

# the "last" or -1st block argument is selected because context is always the
# argument -- either the only or the second of two
{% for method in %w(get post put delete ws) %}
macro relative_{{method.id}}(route, &block)
  {{method.id}} fmt_route(\{{route}}) do |\{{block.args.splat}}|
    namespace = \{{block.args[-1]}}.params.query["namespace"]? || Prefix.default_group
    \{{block.body}}
  end
end
{% end %}
