# Constants for use in test data
module Fixtures
  Dir              = File.join File.dirname(__DIR__), "spec", "fixtures"
  Config           = File.join Dir, "config.json"
  NormalUserAPIKey = File.read(File.join Dir, "normal_user.api_key").chomp
end
