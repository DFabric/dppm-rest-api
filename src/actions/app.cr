require "dppm"
# require "../config/route"
require "dppm/prefix"

module DppmRestApi::Actions::App
  extend self
  include Route

  # gather the appropriate configuration option from the context and set it to
  # the app named `app_name`
  private def set_config(context, key, app_name)
    if posted = context.request.body
      Route.prefix.new_app(app_name).set_config key, posted.gets_to_end
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
            message: "Error while iterating over each config key (this probably indicates a bug -- please let us know!)",
            cause: error
        end
      end
    end
    context.response.puts json_text
  end

  def valid_streams(app : DPPM::Prefix::App)
    Array(String).new.tap do |streams|
      app.each_log_stream { |stream| streams << stream }
    end
  end

  RelativeRoute.new "/app" do
    relative_get "/:app_name/config/:key" do |context|
      app_name = context.params.url["app_name"]
      key = context.params.url["key"]
      app = Route.prefix.new_app app_name
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
      set_config context, context.params.url["key"], context.params.url["app_name"]
    end

    relative_put "/:app_name/config/:key" do |context|
      set_config context, context.params.url["key"], context.params.url["app_name"]
    end

    relative_delete "/:app_name/config/:key" do |context|
      Route.prefix
        .new_app(context.params.url["app_name"])
        .del_config context.params.url["key"]
    end

    # All keys, or all config options
    relative_get "/:app_name/config" do |context|
      app_name = context.params.url["app_name"]
      dump_config context, Route.prefix.new_app(app_name)
    end

    # start the service associated with the given application
    relative_put "/:app_name/service/boot" do |context|
      app_name = context.params.url["app_name"]
      app = Route.prefix.new_app(app_name)
      # TODO: rescue and raise an error if service does not exist
      app.service.boot(parse_boolean_param "value", context)
    end

    {% for action in %w(reload restart start stop) %}
  # {[action.id]} the service associated with the given application
  relative_put "/:app_name/service/{{action.id}}" do |context|
    app_name = context.params.url["app_name"]
    app = Route.prefix.new_app(app_name)
    # TODO: rescue and raise an error if service does not exist
    app.service.{{action.id}}
  end

  {% end %}

    # get the status of the service associated with the given application
    relative_get "/:app_name/service/status" do |context|
      app_name = context.params.url["app_name"]
      # TODO: get the status of the service
    end

    # lists dependent library packages
    relative_get "/:app_name/libs" do |context|
      # TODO: list dependencies
    end

    # return the base application package
    relative_get "/:app_name/app" do |context|
      app_name = context.params.url["app_name"]
      build_json context.response do |builder|
        builder.field(app_name) do
          # Route.prefix.new_app(app_name).to_json builder
        end
      end
    end

    # returns information present in pkg.con as JSON
    relative_get "/:app_name/pkg" do |context|
      app_name = context.params.url["app_name"]
      build_json context.response do |builder|
        builder.field(app_name) do
          # Route.prefix.new_app(app_name).pkg.to_json builder
        end
      end
    end

    relative_get "/:app_name/valid-log-streams" do |context|
      build_json context.response do |builder|
        builder.array do
          Route
            .prefix
            .new_app(context.params.url["app_name"])
            .each_log_stream { |stream| builder.string stream }
        end
      end
    end

    # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
    # and stream the results. Otherwise return a JSON-formatted output of the
    # current log data.
    relative_get "/:app_name/logs" do |context|
      app_name = context.params.url["app_name"]
      app = Route.prefix.new_app app_name
      valid_streams = valid_streams app
      stream_names = context.params.query.fetch_all("stream_type") || valid_streams
      # filter irrellevant values
      stream_names &= valid_streams
      if context.params.query["stream"]?
        raise BadRequest.new context, "\
        You must use separate requests to stream more than one log stream. A \
        stream can be selected using the query parameter stream_type." if stream_names.size != 1
        context.response.upgrade do |socket|
          app.get_logs(
            stream_names.first,
            follow: true,
            lines: context.params.query["lines"]?.try &.to_i
          ) { |line| socket.puts line }
        end
      else
        build_json context.response do |builder|
          stream_names.each do |stream|
            builder.field stream do
              builder.array do
                app.get_logs stream, follow: false, lines: context.params.query["lines"]?.try(&.to_i) do |line|
                  builder.string line
                end
              end
            end
          end
        end
      end
    end

    # Install the given package
    relative_post "/:app_name" do |context|
      # TODO: install the package and return its name
    end

    # Delete the given application
    relative_delete "/:app_name" do |context|
      app_name = context.params.url["app_name"]
      Route.prefix
        .new_app(app_name)
        .delete(
          false,
          parse_boolean_param("preserve_database", from: context),
          parse_boolean_param("keep_user_group", from: context)) { true }
    end
  end
end
