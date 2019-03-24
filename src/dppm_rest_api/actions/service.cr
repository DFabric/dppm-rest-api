require "../../config"
require "../../utils"

module DppmRestApi::Actions::Service
  extend self
  # List the managed services. The `system` query parameter may be specified to
  # enumerate all system services rather than just the ones managed by DPPM.
  get root_path do |context|
    if context.current_user? && has_access? context.current_user, Access::Read
    end
    deny_access
  end
  # List each managed service along with its status output.
  get (root_path "/status") do |context|
    if context.current_user? && has_access? context.current_user, Access::Read
    end
    deny_access
  end
  # start the service associated with the given application
  put (root_path "/:service/boot") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Update, service
    end
    deny_access
  end
  # reload the service associated with the given application
  put (root_path "/:service/reload") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Update, service
    end
    deny_access
  end
  # restart the service associated with the given application
  put (root_path "/:service/restart") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Update, service
    end
    deny_access
  end
  # start the service associated with the given application
  put (root_path "/:service/start") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Update, service
    end
    deny_access
  end
  # get the status of the service associated with the given application
  get (root_path "/:service/status") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Read, service
    end
    deny_access
  end
  # stop the service associated with the given application
  put (root_path "/:service/stop") do |context|
    service = context.params.url["service"]?
    if context.current_user? && has_access? context.current_user, Access::Update, service
    end
    deny_access
  end

  private def has_access?(user : UserHash, permission : Access, id = nil)
    if role_data = DppmRestApi.config.file.roles.find { |name, r| name === user["role"]? }
      role_name, role = role_data
      if not_nil_id = id
        return true if role.owned.service.includes?(permission) &&
                       (owned_services = user["owned_services"]?).try(&.is_a?(String)) &&
                       owned_services.as(String).split(',').map { |e| Base64.decode e }.includes?(not_nil_id)
      end
      true if role.not_owned.service.includes? permission
    end
    false
  end
end
