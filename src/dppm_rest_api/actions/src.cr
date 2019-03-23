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
  get root_path "/:type" do |context|
    if context.current_user? && has_access? context.current_user, context.params.url["type"]
      # TODO: List available source packages
    end
    deny_access
  end

  private def has_access?(user, id = nil) : Bool
    if role = DppmRestApi.config.file.roles.find { |r| r.name === user["role"]? }
      if not_nil_id = id
        return true if role.owned.src.includes?(permission) &&
                       user["owned_srcs"]?.try(&.includes?(not_nil_id))
      end
      true if role.not_owned.src.includes? Access::Read
    end
    false
  end
end
