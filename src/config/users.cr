require "json"
require "../ext/scrypt"

module DppmRestApi
  @[Flags]
  enum Access : UInt8
    Create, Read, Update, Delete

    def self.super_user
      Access::All
    end

    def self.deny
      Access::None
    end

    def self.new(pull : JSON::PullParser)
      from_value pull.read_int
    end

    def to_json
      value
    end

    def self.from_json(value : Number)
      from_value number
    end

    def self.from_value(value : Int)
      raise "invalid variant of Access recieved: #{value}" if value > Access::All.value || value < 0
      variant = Access::None
      {% for variant in @type.constants %}
      variant |= {{variant.id}} if (value & {{variant.id}}.value) > 0
      {% end %}
      variant
    end
  end

  struct User
    API_KEY_SIZE = 63_u8
    include JSON::Serializable
    property api_key_hash : Scrypt::Password
    property role : String
    @[JSON::Field(key: "owned apps")]
    property owned_apps : Array(String)
    @[JSON::Field(key: "owned pkgs")]
    property owned_pkgs : Array(String)
    @[JSON::Field(key: "owned services")]
    property owned_services : Array(String)
    @[JSON::Field(key: "owned srcs")]
    property owned_srcs : Array(String)

    def initialize(@api_key_hash,
                   @role,
                   @owned_apps,
                   @owned_pkgs,
                   @owned_services,
                   @owned_srcs); end

    def self.new(api_key_hash, role)
      new api_key_hash, role, [] of String, [] of String, [] of String, [] of String
    end

    def self.create(role : String) : {String, self}
      api_key = Random::Secure.base64 API_KEY_SIZE
      {api_key, new(Scrypt::Password.create(api_key), role)}
    end

    def to_h : UserHash
      {% begin %}
      UserHash{
        {% for owned in @type.methods.select { |m| m.name.starts_with?("owned") && !m.name.ends_with?("=") } %}
        "{{owned.name.id}}" => {{owned.name.id}}.map { |e| Base64.urlsafe_encode(e) }.join(','), {% end %}
        "role" => role
      }
      {% end %}
    end
  end

  struct Role
    include JSON::Serializable
    property name : String

    property owned : AccessControlList
    @[JSON::Field(key: "not owned")]
    property not_owned : AccessControlList

    def initialize(@name, @owned, @not_owned); end

    def self.new(name)
      new name, AccessControlList.new, AccessControlList.new
    end

    struct AccessControlList
      include JSON::Serializable
      property apps = DppmRestApi::Access.deny
      property pkgs = DppmRestApi::Access.deny
      property services = DppmRestApi::Access.deny
      property srcs = DppmRestApi::Access.deny
      def initialize;end
    end
  end
end
