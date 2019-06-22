require "dppm"
require "dppm/prefix"

module DppmRestApi::Actions
  module App
    extend self
    include Utils

    # gather the appropriate configuration option from the context and set it to
    # the app named `app_name`
    private def set_config(context, key, app_name)
      if posted = context.request.body
        get_prefix_or_default(from: context).new_app(app_name).set_config key, posted.gets_to_end
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
      if Actions.has_access? context, Access::Read
        app = get_prefix_or_default(from: context).new_app app_name
        if key == "."
          dump_config context, app
        else
          begin
            {data: app.get_config key}.to_json context.response
          rescue err : ConfigKeyError
            raise NotFound.new context, cause: err
          end
        end
        next context
      end
      raise Unauthorized.new context
    end
    relative_post "/:app_name/config/:key" do |context|
      if Actions.has_access? context, Access::Create
        set_config context, context.params.url["key"], context.params.url["app_name"]
        next context
      end
      raise Unauthorized.new context
    end
    relative_put "/:app_name/config/:key" do |context|
      if Actions.has_access? context, Access::Update
        set_config context, context.params.url["key"], context.params.url["app_name"]
        next context
      end
      raise Unauthorized.new context
    end
    relative_delete "/:app_name/config/:key" do |context|
      if Actions.has_access? context, Access::Delete
        get_prefix_or_default(from: context)
          .new_app(context.params.url["app_name"])
          .del_config context.params.url["key"]
        next context
      end
      raise Unauthorized.new context
    end
    # All keys, or all config options
    relative_get "/:app_name/config" do |context|
      app_name = context.params.url["app_name"]
      if Actions.has_access? context, Access::Read
        dump_config context, get_prefix_or_default(from: context).new_app(app_name)
        next context
      end
      raise Unauthorized.new context
    end
    # start the service associated with the given application
    relative_put "/:app_name/service/boot" do |context|
      if Actions.has_access? context, Access::Update
        # TODO: boot the service
        next context
      end
      raise Unauthorized.new context
    end
    # reload the service associated with the given application
    relative_put "/:app_name/service/reload" do |context|
      if Actions.has_access? context, Access::Update
        # TODO: reload the service
        next context
      end
      raise Unauthorized.new context
    end
    # restart the service associated with the given application
    relative_put "/:app_name/service/restart" do |context|
      if Actions.has_access? context, Access::Update
        # TODO: reboot the service
        next context
      end
      raise Unauthorized.new context
    end
    # start the service associated with the given application
    relative_put "/:app_name/service/start" do |context|
      if Actions.has_access? context, Access::Update
        # TODO: start the service
        next context
      end
      raise Unauthorized.new context
    end
    # get the status of the service associated with the given application
    relative_get "/:app_name/service/status" do |context|
      if Actions.has_access? context, Access::Read
        # TODO: get the status of the service
        next context
      end
      raise Unauthorized.new context
    end
    # stop the service associated with the given application
    relative_put "/:app_name/service/stop" do |context|
      if Actions.has_access? context, Access::Update
        # TODO: stop the service
        next context
      end
      raise Unauthorized.new context
    end
    # lists dependent library packages
    relative_get "/:app_name/libs" do |context|
      if Actions.has_access? context, Access::Read
        # TODO: list dependencies
        next context
      end
      raise Unauthorized.new context
    end
    # return the base application package
    relative_get "/:app_name/app" do |context|
      if Actions.has_access? context, Access::Read
        # TODO: return the base application package
        next context
      end
      raise Unauthorized.new context
    end
    # returns information present in pkg.con as JSON
    relative_get "/:app_name/pkg" do |context|
      if Actions.has_access? context, Access::Read
        # TODO: return package data
        next context
      end
      raise Unauthorized.new context
    end
    # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
    # and stream the results. Otherwise return a JSON-formatted output of the
    # current log data.
    relative_get "/:app_name/logs" do |context|
      if Actions.has_access? context, Access::Read
        # TODO: upgrade to websocket or output logs to date
        next context
      end
      raise Unauthorized.new context
    end
    # Install the given package
    relative_put "/:app_name" do |context|
      if Actions.has_access? context, Access::Create
        # TODO: install the package and return its name
        next context
      end
      raise Unauthorized.new context
    end
    # Delete the given application
    relative_delete "/:app_name" do |context|
      if Actions.has_access? context, Access::Delete
        # TODO: delete the app
        next context
      end
      raise Unauthorized.new context
    end
  end
end
