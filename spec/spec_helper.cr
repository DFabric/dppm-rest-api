require "spec"
require "spec-kemal"
require "../src/dppm_rest_api"

TEST_DIR = "#{__DIR__}/test-data"
DppmRestApi.config = DppmRestApi::Config.new file_loc: ::File.join(TEST_DIR, "config")
