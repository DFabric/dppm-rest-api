require "./ext/scrypt_password"
require "json"
require "./config/helpers"

struct DppmRestApi::Config
  include JSON::Serializable

  DEFAULT_DATA_DIR = "./data/"
  private FILE             = "permissions.json"
  property groups : Array(Group)
  property users : Array(User)

  @[JSON::Field(ignore: true)]
  property file_path : Path = Path[DEFAULT_DATA_DIR, FILE]

  def group_view(user : User) : GroupView
    GroupView.new user, groups
  end

  # :nodoc:
  def initialize(@groups : Array(Group) = Array(Group).new, @users : Array(User) = Array(User).new, data_dir : String = DEFAULT_DATA_DIR)
    @file_path = Path[data_dir, FILE]
  end

  def self.read(data_dir : String = DEFAULT_DATA_DIR) : self
    config_file = Path[data_dir, FILE]
    if File.exists? config_file
      permissions_config = nil
      File.open config_file do |data|
        permissions_config = Config.from_json data
        permissions_config.file_path = config_file
        permissions_config
      end
    else
      Config.new data_dir: data_dir
    end
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

  # Saves the configuration to a file at `filepath`.
  def sync_to_disk : Nil
    prefix = @file_path.basename suffix: ".json"
    suffix = @file_path.extension
    dirname = @file_path.dirname
    Dir.mkdir dirname if !Dir.exists? dirname
    tmp_file = File.tempfile prefix, suffix, dir: dirname do |file|
      to_json file, indent: 2
    end
    # to prevent data loss in case of loss of power during the file write.
    File.rename tmp_file.path, @file_path.to_s
  ensure
    begin
      tmp_file.try &.delete
    rescue Errno
    end
  end

  def to_json(io : IO, *, indent : String | Int32? = nil)
    JSON.build io, indent: indent do |builder|
      to_json builder
    end
  end
end

require "./config/*"
