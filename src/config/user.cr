require "json"
require "uuid"
require "uuid/json"
require "./group"

struct DppmRestApi::Config::User
  API_KEY_SIZE = 63_u8
  include JSON::Serializable
  property api_key_hash, name
  getter group_ids, id

  def initialize(@api_key_hash : Scrypt::Password,
                 @group_ids : Set(Int32),
                 @name : String,
                 @id : UUID)
  end

  def self.new(api_key_hash string : String,
               groups : Set(Int32),
               name : String,
               id : UUID)
    new Scrypt::Password.new(string), groups.to_set, name, id
  end

  @[AlwaysInline]
  def self.create(groups : Set(Group), name : String) : {String, self}
    create groups.map { |g| g.id }, name
  end

  def self.create(groups : Set(Int), name : String) : {String, self}
    api_key = Random::Secure.base64 API_KEY_SIZE
    {api_key, new(Scrypt::Password.create(api_key), groups, name, UUID.random)}
  end

  def to_h : JWTCompatibleHash
    JWTCompatibleHash{"groups"       => serialized_groups,
                      "name"         => @name,
                      "API key hash" => api_key_hash.to_s,
                      "id"           => @id.to_s}
  end

  def self.from_h(hash data : JWTCompatibleHash)
    if (groups = data["groups"]?).is_a?(String) &&
       (name = data["name"]?).is_a?(String) &&
       (id = data["id"]?).is_a?(String) &&
       (key = data["API key hash"]?).is_a? String
      new key, deserialize(groups), name, UUID.new id
    end
  rescue ArgumentError
    nil
  end

  private def serialized_groups : String
    @group_ids.map(&.to_s base: 16).join(",")
  end

  def self.deserialize(groups : String)
    set = Set(Int32).new
    groups.split separator: ',', remove_empty: true do |id|
      set << id.to_i base: 16
    end
    set
  end

  def join_group(id : Int32)
    @group_ids << id
  end

  def leave_group(id : Int32)
    @group_ids.delete id
  end

  # Show a human-readable representation of the important information about a
  # user.
  def to_pretty_s
    "Name: #{name}; Member of: #{group_ids.join(", ")}"
  end

  # Build a JSON response, like JSON::Serializable, but allow certain
  # variables to be excluded for this instance.
  def to_json(builder : JSON::Builder, *, except : Enumerable(Symbol))
    builder.object do
      {% for ivar in @type.instance_vars %}
        unless except.includes? {{ivar.name.symbolize}}
          builder.field({{ivar.name.stringify}}) { {{ivar}}.to_json builder }
        end
      {% end %}
    end
  end

  # :ditto:
  def to_json(builder : JSON::Builder, *, except : Symbol)
    to_json builder, except: StaticArray[except]
  end
end

alias JWTCompatibleHash = Hash(String, String | Int32 | Bool?)
