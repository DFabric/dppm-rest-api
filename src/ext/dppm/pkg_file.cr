require "dppm/prefix"

struct DPPM::Prefix::PkgFile
  # Yield each instance variable to the block
  def each_ivar
    {% for ivar in @type.instance_vars %}
      yield {{ ivar.stringify }}, @{{ivar.name}}
    {% end %}
  end

  def each_serializable_ivar(&block)
    {% for ivar in @type.instance_vars %}
      {% unless %w(any config tags version tasks).includes? ivar.name.stringify %}
        yield {{ ivar.stringify }}, @{{ivar.name}}
      {% end %}
    {% end %}
  end

  # Build a JSON response of the config keys mapped to their values, but only
  # if they're specified in the *keys* list. If *keys* is empty, all values
  # are forwarded
  def to_json(builder : JSON::Builder, keys : Enumerable(String)) : Nil
    return to_json builder if keys.empty?
    builder.object do
      each_serializable_ivar do |key, value|
        if keys.includes? key
          builder.field(key) do
            value.to_json builder
          end
        end
      end
    end
  end

  def to_json(builder, keys : String) : Nil
    to_json builder, keys: {keys}
  end

  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      each_serializable_ivar do |key, value|
        builder.field(key) { value.to_json builder }
      end
    end
    builder
  end
end
