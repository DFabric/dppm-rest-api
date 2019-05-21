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
    when :int
      number = parser.read_int
      puts "got numeric access to parse " + number.to_s
      from_value number
    when :string
      read = parser.read_string
      puts "got string access to parse " + read
      if read.includes? '|'
        value = Access::None
        read.split('|').each do |substr|
          parsed = parse substr.strip
          value |= parsed
          puts "got substring '#{substr}' which was parsed to '#{parsed}'. Value is now '#{value}'"
        end
        value
      else
        parse? read
      end
    when :begin_array
      value = Access::None
      parser.read_array do
        str = parser.read_string
        parsed = parse str
        value |= parsed
        puts "got array element '#{str}' which was parsed to '#{parsed}'. Value is now '#{value}'"
      end
      value
    else
      raise JSON::ParseException.new <<-HERE, parser.line_number, parser.column_number
      Trying to parse Access (integer, string, or array of strings) but found
      a value of type "#{parser.kind}".
      HERE
    end
  end

  def to_json
    '"' + to_s + '"'
  end

  def to_json(builder : JSON::Builder)
    builder.string to_s
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
