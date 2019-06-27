require "semantic_version"

struct SemanticVersion
  def to_json(builder : JSON::Builder)
    builder.string to_s
  end

  def to_json(io : IO)
    JSON.build(io) { |builder| to_json builder }
  end

  def to_json
    String.build { |io| to_json io }
  end

  def self.new(parser : JSON::PullParser)
    self.parse parser.read_string
  end

  def self.from_json(io : IO)
    from_json io.gets || raise ArgumentError.new "io was empty"
  end

  def self.from_json(text : String)
    parse text.lchop('"').rchop('"')
  end
end
