require "json"
require "./group"

struct DppmRestApi::Config::User
  API_KEY_SIZE = 63_u8
  include JSON::Serializable
  property api_key_hash : Scrypt::Password
  getter group_ids : Set(Int32)
  property name : String

  def initialize(@api_key_hash,
                 @group_ids : Set(Int32),
                 @name : String)
  end

  def self.new(api_key_hash string : String, groups, name)
    new Scrypt::Password.new(string), groups.to_set, name
  end

  @[AlwaysInline]
  def self.create(groups : Set(Group), name : String) : {String, self}
    create groups.map { |g| g.id }, name
  end

  def self.create(groups : Set(Int), name : String) : {String, self}
    api_key = Random::Secure.base64 API_KEY_SIZE
    {api_key, new(Scrypt::Password.create(api_key), groups, name)}
  end

  def to_h : JWTCompatibleHash
    JWTCompatibleHash{"groups"       => serialized_groups,
                      "name"         => @name,
                      "API key hash" => api_key_hash.to_s}
  end

  def self.from_h(hash data : JWTCompatibleHash)
    if (groups = data["groups"]?).is_a?(String) &&
       (name = data["name"]?).is_a?(String) &&
       (key = data["API key hash"]?).is_a? String
      new key, deserialize(groups), name
    end
  rescue ArgumentError
    nil
  end

  private def serialized_groups : String
    @group_ids.map(&.to_s base: 16).join(",")
  end

  def self.deserialize(groups : String)
    groups.split(',').map { |id| id.to_i base: 16 }
  end

  def join_group(id : Int32)
    @group_ids << id
  end

  def leave_group(id : Int32)
    @group_ids.delete id
  end

  def to_pretty_s
    "Name: #{name}; Member of: #{group_ids.join(", ")}"
  end
end

alias JWTCompatibleHash = Hash(String, String | Int32 | Bool?)
