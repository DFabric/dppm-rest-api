require "kemal"
require "./config"
require "./actions"

module DppmRestApi
  PERMISSIONS_FILE = "permissions.json"

  class_property permissions_config : Config do
    raise "no permissions file is defined!"
  end

  def self.run(host : String, port : Int32, data_dir : String)
    ::File.open Path[data_dir, PERMISSIONS_FILE] do |data|
      @@permissions_config = Config.from_json data
    end

    Kemal.config.add_handler Actions.auth_handler

    Actions.has_access = ->(context : HTTP::Server::Context, permission : Access) {
      if received_user = context.current_user?.try { |user| Config::User.from_h hash: user }
        return true if received_user.find_group? do |group|
                         group.can_access?(
                           context.request.path,
                           context.request.query_params,
                           permission
                         )
                       end
      end
      false
    }

    initialize_error_handlers
    # Kemal doesn't like IPV6 brackets
    Kemal.config.host_binding = host.lchop('[').rchop(']')
    Kemal.run port: port
  end
end
