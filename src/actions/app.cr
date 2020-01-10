require "dppm"
require "dppm/prefix"

module DppmRestApi::Actions::App
  extend self
  include RouteHelpers

  # gather the appropriate configuration option from the context and set it to
  # the app named `app_name`
  private def set_config(context, key, app_name)
    if posted = context.request.body
      Actions.prefix.new_app(app_name).set_config key, posted.gets_to_end
    else
      raise UnprocessableEntity.new context, "setting config data requires a request body"
    end
  end

  # dump a JSON output of all of the configuration options.
  private def dump_config(context, app)
    # Building the JSON before writing it to the response is a small
    # sacrifice in performance, but is necessary to protect against
    # potential issues.
    json_text = String.build do |io|
      build_json io do |json|
        app.each_config_key do |key|
          json.field name: key, value: app.get_config key
        rescue error : ConfigKeyError
          raise NotFound.new context,
            message: "while iterating over each config key (this probably indicates a bug -- please let us know!)",
            cause: error
        end
      end
    end
    context.response.puts json_text
  end

  relative_get "/:app_name/config/:key" do |context|
    app_name = context.params.url["app_name"]
    key = context.params.url["key"]
    Actions.has_access? context, Access::Read
    app = Actions.prefix.new_app app_name
    if key == "."
      dump_config context, app
    else
      begin
        {data: app.get_config key}.to_json context.response
      rescue err : ConfigKeyError
        raise NotFound.new context, cause: err
      end
    end
  end
  relative_post "/:app_name/config/:key" do |context|
    Actions.has_access? context, Access::Create
    set_config context, context.params.url["key"], context.params.url["app_name"]
  end
  relative_put "/:app_name/config/:key" do |context|
    Actions.has_access? context, Access::Update
    set_config context, context.params.url["key"], context.params.url["app_name"]
  end
  relative_delete "/:app_name/config/:key" do |context|
    Actions.has_access? context, Access::Delete
    Actions.prefix
      .new_app(context.params.url["app_name"])
      .del_config context.params.url["key"]
  end
  # All keys, or all config options
  relative_get "/:app_name/config" do |context|
    app_name = context.params.url["app_name"]
    Actions.has_access? context, Access::Read
    dump_config context, Actions.prefix.new_app(app_name)
  end
  # start the service associated with the given application
  relative_put "/:app_name/service/boot" do |context|
    Actions.has_access? context, Access::Update
    # TODO: boot the service
  end
  # reload the service associated with the given application
  relative_put "/:app_name/service/reload" do |context|
    Actions.has_access? context, Access::Update
    # TODO: reload the service
  end
  # restart the service associated with the given application
  relative_put "/:app_name/service/restart" do |context|
    Actions.has_access? context, Access::Update
    # TODO: reboot the service
  end
  # start the service associated with the given application
  relative_put "/:app_name/service/start" do |context|
    Actions.has_access? context, Access::Update
    # TODO: start the service
  end
  # get the status of the service associated with the given application
  relative_get "/:app_name/service/status" do |context|
    Actions.has_access? context, Access::Read
    # TODO: get the status of the service
  end
  # stop the service associated with the given application
  relative_put "/:app_name/service/stop" do |context|
    Actions.has_access? context, Access::Update
    # TODO: stop the service
  end
  # lists dependent library packages
  relative_get "/:app_name/libs" do |context|
    Actions.has_access? context, Access::Read
    # TODO: list dependencies
  end
  # return the base application package
  relative_get "/:app_name/app" do |context|
    Actions.has_access? context, Access::Read
    # TODO: return the base application package
  end
  # returns information present in pkg.con as JSON
  relative_get "/:app_name/pkg" do |context|
    Actions.has_access? context, Access::Read
    # TODO: return package data
  end
  # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
  # and stream the results. Otherwise return a JSON-formatted output of the
  # current log data.
  relative_get "/:app_name/logs" do |context|
    Actions.has_access? context, Access::Read
    # TODO: upgrade to websocket or output logs to date
  end
  # Install the given package
  relative_put "/:app_name" do |context|
    Actions.has_access? context, Access::Create
    # TODO: install the package and return its name
  end
  # Delete the given application
  relative_delete "/:app_name" do |context|
    Actions.has_access? context, Access::Delete
    # TODO: delete the app
  end
end
