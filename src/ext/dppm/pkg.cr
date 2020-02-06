require "dppm/prefix"

class DPPM::Prefix::Pkg
  def to_json(builder : JSON::Builder) : Nil
    builder.object do
      builder.field "package", @package
      builder.field "version", @version
    end
  end
end
