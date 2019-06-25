require "kemal"
require "kemal_jwt_auth"
require "./config"
require "./actions"
require "./errors/api_errors"

module DppmRestApi
  PERMISSIONS_FILE = "permissions.json"

  class_property permissions_config : Config do
    raise "no permissions file is defined!"
  end

  class_property prefix : DPPM::Prefix { raise "no prefix set" }

  def self.access_filter(context : HTTP::Server::Context, permission : Access) : Bool
    if received_user = context.current_user?.try { |user| Config::User.from_h hash: user }
      return true if permissions_config.group_view(received_user).find_group? do |group|
                       group.can_access?(
                         context.request.path,
                         context.request.query_params,
                         permission
                       )
                     end
    end
    false
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    prefix : String = DPPM.default_prefix,
    access_filter : Proc(HTTP::Server::Context, Access, Bool) = ->access_filter(HTTP::Server::Context, Access)
  )
    run host, port, data_dir, DPPM::Prefix.new(prefix), access_filter
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    prefix : DPPM::Prefix,
    access_filter : Proc(HTTP::Server::Context, Access, Bool) = ->access_filter(HTTP::Server::Context, Access)
  )
    ::File.open Path[data_dir, PERMISSIONS_FILE] do |data|
      @@permissions_config = Config.from_json data
    end

    @@prefix = prefix
    Actions.access_filter = access_filter

    # Add authentification handler
    Kemal.config.add_handler KemalJWTAuth::Handler.new(users: permissions_config)

    # Add error handlers
    {% for code in HTTP::Status.constants %}
    if HTTP::Status::{{code}}.value >= 400
      Kemal.config.add_error_handler HTTP::Status::{{code.id}}.value do |context, exception|
        context.response.status_code = exception.status_code.value if exception.responds_to? :status_code
        response_data = ErrorResponse.new exception
        response_data.to_json context.response
        context.response.flush
        response_data.log
        nil
      end
    end
    {% end %}

    # Kemal doesn't like IPV6 brackets
    Kemal.config.host_binding = host.lchop('[').rchop(']')
    Kemal.run port: port
  end
end
