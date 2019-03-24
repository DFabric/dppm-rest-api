require "./utils"
require "./dppm_rest_api/actions"

module DppmRestApi
  VERSION  = "0.1.0"
  TEST_DIR = "#{File.dirname(__DIR__)}/test-data"

  class_property config : Config do
    {% if env("KEMAL_ENV") == "test" %}
    Config.new file_loc: ::File.join(TEST_DIR, "config")
    {% else %}
    Config.from_args ARGV
    {% end %}
  end
end
