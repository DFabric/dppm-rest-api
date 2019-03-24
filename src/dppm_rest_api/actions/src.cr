require "../../config"
require "../../utils"

module DppmRestApi::Actions::Src
  extend self
  get root_path do |context|
    if context.current_user? && has_access? context.current_user
      # TODO: List all available source packages
    end
    deny_access
  end
  # List all available source packages, of either the *lib* or *app* type.
  get (root_path "/:type") do |context|
    if context.current_user? && has_access? context.current_user, context.params.url["type"]
      # TODO: List available source packages
    end
    deny_access
  end

  private def has_access?(user, id = nil) : Bool
    if role_data = DppmRestApi.config.file.roles.find { |name, r| name === user["role"]? }
      role_name, role = role_data
      if not_nil_id = id
        return true if role.owned.src.includes?(Access::Read) &&
                       (owned_srcs = user["owned_srcs"]?).try(&.is_a?(String)) &&
                       owned_srcs.as(String).split(',').map { |e| Base64.decode e }.includes?(not_nil_id)
      end
      true if role.not_owned.src.includes? Access::Read
    end
    false
  end
end
