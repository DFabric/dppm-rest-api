require "../../utils"

module DppmRestApi::Actions::App
  extend self

  get (root_path "/:app_name/config/:key") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: respond with config data for given key for given app name
    end
    deny_access
  end
  post (root_path "/:app_name/config/:key") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Create
      # TODO: set config data for given key for given app name
    end
    deny_access
  end
  put (root_path "/:app_name/config/:key") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: update config data for given key for given app name
    end
    deny_access
  end
  delete (root_path "/:app_name/config/:keys") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Delete
      # TODO: delete config data for given key for given app name
    end
    deny_access
  end
  # All keys, or all config options
  get (root_path "/:app_name/config") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: get config data
    end
    deny_access
  end
  # start the service associated with the given application
  put (root_path "/:app_name/service/boot") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: boot the service
    end
    deny_access
  end
  # reload the service associated with the given application
  put (root_path "/:app_name/service/reload") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: reload the service
    end
    deny_access
  end
  # restart the service associated with the given application
  put (root_path "/:app_name/service/restart") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: reboot the service
    end
    deny_access
  end
  # start the service associated with the given application
  put (root_path "/:app_name/service/start") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: start the service
    end
    deny_access
  end
  # get the status of the service associated with the given application
  put (root_path "/:app_name/service/status") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: get the status of the service
    end
    deny_access
  end
  # stop the service associated with the given application
  put (root_path "/:app_name/service/stop") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Update
      # TODO: stop the service
    end
    deny_access
  end
  # lists dependent library packages
  get (root_path "/:app_name/libs") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: list dependencies
    end
    deny_access
  end
  # return the base application package
  get (root_path "/:app_name/app") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: return the base application package
    end
    deny_access
  end
  # returns information present in pkg.con as JSON
  get (root_path "/:app_name/pkg") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: return package data
    end
    deny_access
  end
  # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
  # and stream the results. Otherwise return a JSON-formatted output of the
  # current log data.
  get (root_path "/:app_name/logs") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: upgrade to websocket or output logs to date
    end
    deny_access
  end
  # Stream the logs for the given application over the websocket connection.
  ws (root_path "/:app_name/logs") do |sock, context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Read
      # TODO: stream logs to sock
    end
    deny_access
  end
  # Install the given package
  put (root_path "/:package_name") do |context|
    pkg_name = context.params.url["package_name"]
    if context.current_user? && (role_data = DppmRestApi.config.file.roles.find { |name, role| name === context.current_user["role"]? })
      role_name, role = role_data
      if role.not_owned.app.create?
        # TODO: install the package and return its name
      end
    end
    deny_access
  end
  # Delete the given application
  delete (root_path "/:app_name") do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && has_access? context.current_user, app_name, Access::Delete
      # TODO: delete the app
    end
    deny_access
  end

  # returns true if the given user has access to the {{@type.id}} named with
  # the given name and permission type
  private def has_access?(user : UserHash, name : String, permission : Access) : Bool
    if role_data = DppmRestApi.config.file.roles.find { |name, role| name == user["role"]? }
      role_name, role = role_data
      if role.owned.app.includes?(permission) &&
         (owned_apps = user["owned_apps"]?).try &.is_a?(String) &&
         owned_apps.as(String).split(',').map { |e| Base64.decode e }.includes?(name)
        true
      end
      true if role.not_owned.app.includes? permission
    end
    false
  end
end
