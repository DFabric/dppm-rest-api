require "./ext/scrypt_password"
require "json"
require "dppm/prefix"
require "./config/helpers"

struct DppmRestApi::Config
  include JSON::Serializable
  property groups : Array(Group)
  property users : Array(User)

  @[JSON::Field(ignore: true)]
  property filepath : Path { raise "The config filepath has not been set, cannot write to file." }

  def group_view(user : User) : GroupView
    GroupView.new user, groups
  end

  # :nodoc:
  def initialize(@groups : Array(Group), @users : Array(User), @filepath = nil)
  end

  def find_and_authenticate!(body) : Config::User?
    data = ReceivedUser.from_json body
    if key = data.auth?
      users.find &.api_key_hash.verify key
    end
  rescue JSON::ParseException
    # Body was not formatted properly.
    nil
  end

  def sync_to_disk : Nil
    write_to filepath
  end

  @[AlwaysInline]
  def write_to(path : String) : Nil
    write_to Path.new path
  end

  def write_to(path : Path) : Nil
    prefix = path.basename suffix: ".json"
    suffix = path.extension
    tmp_file = File.tempfile prefix, suffix, dir: path.dirname do |file|
      self.to_json file, indent: 2
    end
    # to prevent data loss in case of loss of power during the file write.
    File.rename tmp_file.path, path.to_s
  ensure
    begin
      tmp_file.try &.delete
    rescue Errno
    end
    self
  end

  def to_json(io : IO, *, indent : String | Int32? = nil)
    JSON.build io, indent: indent do |builder|
      to_json builder
    end
  end
end

require "./config/*"
