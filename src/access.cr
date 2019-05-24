@[Flags]
enum DppmRestApi::Access : UInt8
  Create; Read; Update; Delete

  def self.super_user
    Access::All
  end

  def self.deny
    Access::None
  end

  def self.new(pull parser : JSON::PullParser) : Access
    case parser.kind
    when :int
      number = parser.read_int
      from_value number
    when :string
      read = parser.read_string
      if read.includes? '|'
        value = Access::None
        read.split('|').each do |substr|
          value |= parse substr.strip
        end
        value
      else
        parse read
      end
    when :begin_array
      value = Access::None
      parser.read_array do
        str = parser.read_string
        parsed = parse str
        value |= parsed
      end
      value
    else
      raise JSON::ParseException.new <<-HERE, parser.line_number, parser.column_number
      Trying to parse Access (integer, string, or array of strings) but found
      a value of type "#{parser.kind}".
      HERE
    end
  end

  def to_json(**options)
    JSON.build(**options) { |builder| to_json builder }
  end

  def to_json(builder : JSON::Builder)
    builder.array do
      each do |variant|
        builder.string variant.to_s
      end
    end
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
