require "./access"
require "./ext/scrypt_password"
require "json"
require "kemal_jwt_auth"
require "./config/received_user"

struct DppmRestApi::Config
  include JSON::Serializable
  include KemalJWTAuth::UsersCollection
  property groups : Array(Group)
  property users : Array(User)

  # :nodoc:
  def initialize(@groups, @users)
  end

  def find_and_authenticate!(body) : Config::User?
    data = ReceivedUser.from_json body
    if key = data.auth?
      users.find { |user| user.api_key_hash.verify key }
    end
  rescue JSON::ParseException
    # Body was not formatted properly.
    nil
  end

  # returns true if the given user has access to the given context with the given
  # permission type
  def self.has_access?(context : HTTP::Server::Context, permission : DppmRestApi::Access)
    if received_user = context.current_user?.try { |user| DppmRestApi::Config::User.from_h hash: user }
      return true if received_user.find_group? do |group|
                       group.can_access?(
                         context.request.path,
                         context.request.query_params,
                         permission
                       )
                     end
    end
    false
  end

  @[AlwaysInline]
  def write_to(path : String)
    write_to Path.new path
  end

  def write_to(path : Path) : Void
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
