require "dppm"
# require "../config/route"
require "dppm/prefix"

module DppmRestApi::Actions::App
  extend self

  # Pull the context from the context's query parameter or use the default
  # provided by the CLI.
  macro prefix
    context.params.query["prefix"]? || "" # TODO improve like DppmRestApi.config.default_prefix
  end

  # gather the appropriate configuration option from the context and set it to
  # the app named `app_name`
  private def set_config(context, key, app_name)
    if posted = context.request.body
      Prefix.new(prefix).new_app(app_name).set_config key, posted.gets_to_end
    else
      Actions.throw_error context, "setting config data requires a request body"
    end
  end

  # dump a JSON output of all of the configuration options.
  private def dump_config(context, app)
    JSON.build context.response do |json|
      json.object do
        json.field "data" do
          json.object do
            app.each_config_key do |key|
              json.field name: key, value: app.get_config key
            end
          end
        end
        json.field "errors" do
          json.array { }
        end
      end
    end
    context.response.flush
  end

  relative_get "/:app_name/config/:key" do |context|
    app_name = context.params.url["app_name"]
    key = context.params.url["key"]
    if context.current_user? && Config.has_access? context, Access::Read
      app = Prefix.new(prefix).new_app app_name
      if key == "."
        dump_config context, app
      elsif config = app.get_config(key)
        context.response.puts({"data" => config, "errors" => [] of Nil}.to_json)
      else
        Actions.throw_error context, "no config with app named '#{app_name}' found", status_code: 404
      end
      next context
    end
    deny_access! to: context
  end
  relative_post "/:app_name/config/:key" do |context|
    if context.current_user? && Config.has_access? context, Access::Create
      set_config context, context.params.url["key"], context.params.url["app_name"]
      next context
    end
    deny_access! to: context
  end
  relative_put "/:app_name/config/:key" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      set_config context, context.params.url["key"], context.params.url["app_name"]
      next context
    end
    deny_access! to: context
  end
  relative_delete "/:app_name/config/:key" do |context|
    if context.current_user? && Config.has_access? context, Access::Delete
      Prefix.new(prefix)
        .new_app(context.params.url["app_name"])
        .del_config context.params.url["key"]
      next context
    end
    deny_access! to: context
  end
  # All keys, or all config options
  relative_get "/:app_name/config" do |context|
    app_name = context.params.url["app_name"]
    if context.current_user? && Config.has_access? context, Access::Read
      dump_config context, Prefix.new(prefix).new_app(app_name)
      next context
    end
    deny_access! to: context
  end
  # start the service associated with the given application
  relative_put "/:app_name/service/boot" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      # TODO: boot the service
      next context
      puts "user found!"
    end
    pp! deny_access! to: context
  end
  # reload the service associated with the given application
  relative_put "/:app_name/service/reload" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      # TODO: reload the service
      next context
    end
    deny_access! to: context
  end
  # restart the service associated with the given application
  relative_put "/:app_name/service/restart" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      # TODO: reboot the service
      next context
    end
    deny_access! to: context
  end
  # start the service associated with the given application
  relative_put "/:app_name/service/start" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      # TODO: start the service
      next context
    end
    deny_access! to: context
  end
  # relative_get the status of the service associated with the given application
  relative_put "/:app_name/service/status" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: get the status of the service
      next context
    end
    deny_access! to: context
  end
  # stop the service associated with the given application
  relative_put "/:app_name/service/stop" do |context|
    if context.current_user? && Config.has_access? context, Access::Update
      # TODO: stop the service
      next context
    end
    deny_access! to: context
  end
  # lists dependent library packages
  relative_get "/:app_name/libs" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: list dependencies
      next context
    end
    deny_access! to: context
  end
  # return the base application package
  relative_get "/:app_name/app" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: return the base application package
      next context
    end
    deny_access! to: context
  end
  # returns information present in pkg.con as JSON
  relative_get "/:app_name/pkg" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: return package data
      next context
    end
    deny_access! to: context
  end
  # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
  # and stream the results. Otherwise return a JSON-formatted output of the
  # current log data.
  relative_get "/:app_name/logs" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: upgrade to websocket or output logs to date
      next context
    end
    deny_access! to: context
  end
  # Stream the logs for the given application over the websocket connection.
  relative_ws "/:app_name/logs" do |sock, context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: stream logs to sock
      sock.tap do
        # trick ameba into ignoring the sock variable
      end
      next context
    end
    deny_access! to: context
  end
  # Install the given package
  relative_put "/:package_name" do |context|
    if context.current_user? && Config.has_access? context, Access::Create
      # TODO: install the package and return its name
      next context
    end
    deny_access! to: context
  end
  # Delete the given application
  relative_delete "/:app_name" do |context|
    if context.current_user? && Config.has_access? context, Access::Delete
      # TODO: delete the app
      next context
    end
    deny_access! to: context
  end
end
