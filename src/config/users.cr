require "json"
require "scrypt"

module DppmRestApi
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
        "role" => role,
        {% for owned in @type.methods.select &.starts_with?("owned") %}
        "{{owned.id}}" => {{owned.id}}, {% end %} }
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
      property app = Access.deny
      property pkg = Access.deny
      property service = Access.deny
      property src = Access.deny
    end

    @[Flags]
    enum Access : UInt8
      Create, Read, Update, Delete

      def self.super_user
        Access::All
      end

      def self.deny
        Access::None
      end

      def to_json
        value
      end

      def self.from_json(value : Number)
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
  end
end
