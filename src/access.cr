@[Flags]
enum DppmRestApi::Access : UInt8
  Create; Read; Update; Delete

  def self.super_user
    Access::All
  end

  def self.deny
    Access::None
  end

  def self.new(pull parser : JSON::PullParser)
    case parser.kind
    when :int then from_value parser.read_int
    when :string
      read = parser.read_string
      if read.includes? '|'
        value = Access::None
        read.split('/').each { |ss| value |= parse ss }
        return value
      else
        return parse? read
      end
    when :begin_array
      value = Access::None
      parser.read_array { value |= parse parser.read_string }
      value
    else
      raise JSON::ParseException.new <<-HERE, parser.line_number, parser.column_number
      Trying to parse Access (integer, string, or array of strings) but found
      a value of type "#{parser.kind}".
      HERE
    end
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
