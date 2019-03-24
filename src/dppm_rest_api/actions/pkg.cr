require "../../utils"
require "../../config"

module DppmRestApi::Actions::Pkg
  extend self
  ALL_PKGS = root_path
  ONE_PKG  = root_path "/:id"
  # List built packages
  get ALL_PKGS do |context|
    if context.current_user? && has_access? context.current_user, Access::Read
      # TODO: list all built packages
    end
    deny_access
  end
  # Clean unused built packages
  delete ALL_PKGS do |context|
    if context.current_user? && has_access? context.current_user, Access::Delete
      # TODO: delete all unused built packages
    end
    deny_access
  end
  # Query information about a given package
  get ONE_PKG do |context|
    if context.current_user? && has_access? context.current_user, Access::Read, context.params.url["id"]?
      # TODO: Query information about the given package
    end
    deny_access
  end
  # Delete a given package
  delete ONE_PKG do |context|
    if context.current_user? && has_access? context.current_user, Access::Delete, context.params.url["id"]?
      # TODO: Query information about the given package
    end
    deny_access
  end

  private def has_access?(user, permission, id = nil)
    if role = DppmRestApi.config.file.roles.find { |role| role.name === user["role"]? }
      if not_nil_id = id
        return true if role.owned.pkgs.includes?(permission) &&
                       (owned_pkgs = user["owned_pkgs"]?).try &.is_a?(String) &&
                       owned_pkgs.as(String).split(',').map { |e| Base64.decode e }.includes?(not_nil_id)
      end
      true if role.not_owned.pkgs.includes? permission
    end
    false
  end

  module Build
    # Build a package, returning the ID of the built image, and perhaps a status
    # message? We could also use server-side events or a websocket to provide the
    # status of this action as it occurs over the API, rather than just returning
    # a result on completion.
    post (root_path "/:package") do |context|
    end
  end
end
