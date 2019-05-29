require "dppm/prefix/pkg"

class Prefix::Pkg
  def serialize_configuration(key : String?) : String
    String.build { |text| serialize_configuration key, into: text }
  end

  def serialize_configuration(key : String?, into io : IO)
    JSON.build io { |builder| serialize_configuration key, into: builder }
  end

  def serialize_configuration(key : String, into builder : JSON::Builder)
    errors = [] of String
    builder.object do
      builder.field package do
        builder.object do
          builder.field key do
            builder.string value: get_config key
          rescue e
            raise e unless e.starts_with? "config key not found"
            errors << e.message
            builder.string "ERROR"
          end
        end
      end
      builder.field "errors" do
        builder.array do
          errors.each { |err| builder.string err }
          yield builder
        end
      end
    end
  ensure
    builder.end_object if builder.@state.last === ObjectState
  end

  # No specific key was requested, respond with all of the config options
  # for this package and all dependent packages
  def serialize_configuration(x : Nil, into builder : JSON::Builder)
    serialize_configuration into: builder { |yielded_builder| yield yielded_builder }
  end

  # :ditto:
  def serialize_configuration(into builder : JSON::Builder)
    builder.object do
      builder.field package do
        builder.object do
          pkg_file.config_vars.try &.each_key do |key|
            serialize_configuration key, into: builder
          end
        end
      end
    end
  end
end
