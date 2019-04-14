require "dppm/cli"
require "./dppm_rest_api"

module DppmRestApi::CLI
  def self.run_server(config, port, host, **args)
    if port.is_a? String
      port = port.to_i
    end
    if config
      dppm_config = Prefix::Config.new File.read config
      port ||= dppm_config.port
      host ||= dppm_config.host
    end
    DppmRestApi.run port, host
  end
end

# DPPM CLI isn't namespaced yet
CLI.run(
  server: {
    info:     "DPPM REST API server",
    commands: {
      run: {
        info:      "Run the server",
        action:    "DppmRestApi::CLI.run_server",
        variables: {
          host: {
            info:    "host to listen",
            default: Prefix.default_dppm_config.host,
          },
          port: {
            info:    "port to bind",
            default: Prefix.default_dppm_config.port,
          },
        },
      },
    },
  }
)
