require "scrypt"

class Scrypt::Password
  def self.new(pull : JSON::PullParser)
    new raw_hash: pull.read_string
  end

  delegate :to_json, to: @raw_hash
end
