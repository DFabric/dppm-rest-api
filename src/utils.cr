require "kemal"
require "kemal_jwt_auth"
require "./config/users"

# Render the given data as JSON to the local `context` variable.
macro render_data(data)
  context.response.content_type = "application/json"
  IO.copy {{data.id}}, context.response
end

macro root_path(route = nil, &block)
  {{
    "/" + @type.stringify
      .downcase
      .gsub(/^DppmRestApi::Actions::/, "")
      .gsub(/::/, "/") + (route || "")
  }}
end

def deny_access!(to context)
  context.response.status_code = 401
  context.response.write "Forbidden.".to_slice
  context.response.flush
  context
end
