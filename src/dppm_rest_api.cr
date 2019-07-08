require "kemal"
require "./ext/path"
require "./config"
require "./actions"

module DppmRestApi
  alias JWTCompatibleHash = Hash(String, String | Int32 | Bool | Nil)

  PERMISSIONS_FILE = "permissions.json"

  class_property permissions_config : Config do
    raise "No permissions file is defined!"
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    webui_folder : Path? = nil,
    prefix : String = DPPM::Prefix.default
  )
    run host, port, data_dir, DPPM::Prefix.new(prefix), webui_folder
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    prefix : DPPM::Prefix,
    webui_folder : Path? = nil
  )
    filepath = Path[data_dir, PERMISSIONS_FILE]
    ::File.open filepath do |data|
      @@permissions_config = Config.from_json data
    end
    permissions_config.filepath = filepath

    Actions.prefix = prefix

    # Add error handlers
    HTTP::Status.each do |status|
      if status.value >= 400
        Kemal.config.add_error_handler status.value do |context, exception|
          if exception.is_a? Actions::HTTPStatusError
            context.response.status_code = exception.status_code.value
          end
          response_data = Actions::ErrorResponse.new exception
          response_data.to_json context.response
          context.response.flush
          response_data.log
          nil
        end
      end
    end

    public_folder path: webui_folder.to_s if webui_folder
    Kemal.config.host_binding = host
    Kemal.run port: port
  end
end
