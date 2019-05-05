require "../spec/fixtures"
require "./errors/**"
require "./dppm_rest_api/utils"
require "./dppm_rest_api/config"
require "./dppm_rest_api/actions"

module DppmRestApi
  VERSION = "0.2.0"

  class_property default_namespace : String { config.default_namespace }
  class_property config : Config { Config.from_args }

  def self.run(port : Int32, host : String)
    # Kemal doesn't like IPV6 brackets
    Kemal.config.host_binding = host.lchop('[').rchop(']')
    Kemal.run port: port
  end
end
