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

    def self.from_value(value : Number)
      {% begin %}
      case value
        {% for variant in @type.constants %}
      when {{variant.id}}.value then {{variant.id}}
        {% end %}
      else raise "invalid variant Access recieved: #{value}"
      end
      {% end %}
    end
  end

  struct User
    include JSON::Serializable
    property api_key_hash : Scrypt::Password
    property role : String
    property owned_apps : Array(String)
    property owned_pkgs : Array(String)
    property owned_services : Array(String)
    property owned_srcs : Array(String)

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
    property not_owned : AccessControlList

    struct AccessControlList
      include JSON::Serializable
      property app = DppmRestApi::Access.deny
      property pkg = DppmRestApi::Access.deny
      property service = DppmRestApi::Access.deny
      property src = DppmRestApi::Access.deny
    end
  end
end
