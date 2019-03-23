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

module AccessControl
  macro finished
    # returns true if the given user has access to the {{@type.id}} named with
    # the given name and permission type
    def has_access?(user : UserHash, name : String, permission : Access) : Bool
      if role = DppmRestApi.config.file.roles.find { |role| role.name == user["role"]? }
        if (user["owned_{{@type.id.downcase}}s"]?.try &.includes?(name) && role.owned.{{@type.id.downcase}}s.{{permission.id}}?) ||
           role.not_owned.{{@type.id.downcase}}s.{{permission.id.downcase}}?
          true
        end
      end
      false
    end
  end
  macro deny_access
    context.response.status = 401
    context.response.write "Forbidden."
    context.response.flush
    context
  end
end
