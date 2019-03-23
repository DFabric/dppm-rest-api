require "kemal"
require "kemal_jwt_auth"
require "./config/users"

# Render the given data as JSON to the local `context` variable.
macro render_data(data)
  context.response.content_type = "application/json"
  IO.copy {{data.id}}, context.response
end

macro root_path(route)
  {{
    "/" + @type.stringify
      .downcase
      .gsub(/^DppmRestApi::Actions::/, "")
      .gsub(/::/, "/") + route
  }}
end

macro deny_access
  context.response.status = 401
  context.response.write "Forbidden."
  context.response.flush
  context
end
