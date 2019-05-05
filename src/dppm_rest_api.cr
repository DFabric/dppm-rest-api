require "kemal"
require "./errors/*"
require "./config"
require "./actions"

module DppmRestApi
  DEFAULT_DATA_DIR = "./data/"
  PERMISSIONS_FILE = "permissions.json"
  API_DOCUMENT     = DEFAULT_DATA_DIR + "api-options.json"

  class_getter permissions_config : Config do
    raise "no permissions file is defined!"
  end

  def self.run(host : String, port : Int32, data_dir : String)
    ::File.open data_dir + '/' + PERMISSIONS_FILE do |data|
      @@permissions_config = Config.from_json data
    end

    # Kemal doesn't like IPV6 brackets
    Kemal.config.host_binding = host.lchop('[').rchop(']')
    Kemal.run port: port

    add_handler Actions.auth_handler
  end
end
