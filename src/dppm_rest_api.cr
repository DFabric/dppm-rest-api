require "./utils"
require "./config"
require "./dppm_rest_api/actions"

module DppmRestApi
  VERSION = "0.1.0"
  # TODO: move this to ./spec
  TEST_DIR = "#{File.dirname(__DIR__)}/test-data"

  # Temporary fix to compile the program
  record Config, file : Config::File, file_loc : String

  class_property config : Config do
    file_loc = ::File.join(TEST_DIR, "config")
    file = ::File.open file_loc do |data|
      Config::File.from_json data
    end
    Config.new file, file_loc
  end

  def self.run(port : Int32, host : String)
    # Kemal doesn't like IPV6 brackets
    Kemal.config.host_binding = host.lchop('[').rchop(']')
    Kemal.run port: port
  end
end
