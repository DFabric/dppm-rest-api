require "kemal"
require "./ext/path"
require "./config"
require "./actions"

module DppmRestApi
  alias JWTCompatibleHash = Hash(String, String | Int32 | Bool | Nil)

  class_property permissions_config : Config = Config.new

  def self.read_permissions_config(data_dir : String = Actions::DEFAULT_DATA_DIR)
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    webui_folder : String? = nil,
    prefix : String = DPPM::Prefix.default
  )
    run host, port, data_dir, DPPM::Prefix.new(prefix), webui_folder
  end

  def self.run(
    host : String,
    port : Int32,
    data_dir : String,
    prefix : DPPM::Prefix,
    webui_folder : String? = nil
  )
    @@permissions_config = Config.read data_dir

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

    public_folder path: webui_folder if webui_folder
    Kemal.config.host_binding = host
    Kemal.run port: port
  end
end
