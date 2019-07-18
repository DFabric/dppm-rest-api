struct Path
  def to_json(builder : JSON::Builder) : Nil
    builder.string self.to_s
  end

  def self.new(json : JSON::PullParser)
    new json.read_string
  end
end
