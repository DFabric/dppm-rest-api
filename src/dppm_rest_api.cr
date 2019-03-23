require "./utils"
require "./dppm_rest_api/actions"

module DppmRestApi
  VERSION = "0.1.0"

  class_property config : Config do
    Config.from_args ARGV
  end
end
