require "./access"
require "./ext/scrypt_password"

struct DppmRestApi::Config
  include JSON::Serializable
  property groups : Array(Group)
  property users : Array(User)

  def user(*, named username : String) : User?
    users.find { |user| user.name == username }
  end

  def user(*, authenticated_with api_key : String)
    users.find { |user| user.api_key_hash == api_key }
  end

  def group(*, named group_name : String) : Group?
    groups.find { |group| group.name == group_name }
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

  def write_to(path : Path)
    prefix = path.basename
    suffix = path.extension
    tmp_file = File.tempfile prefix, suffix, dir: path.dirname do |file|
      self.to_json file
    end
    # to prevent data loss in case of loss of power during the file write.
    File.rename tmp_file.path, path.to_s
  ensure
    if tf = tmp_file
      File.delete tf.path
    end
  end
end

require "./config/*"
