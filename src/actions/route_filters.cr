# A series of filters, which may be parsed from the current context. They
# currently allow filtering the #pkg_file attributes of DPPM::Prefix's Pkg,
# App, and Src.
class DppmRestApi::Actions::RouteFilters
  @data = Hash(String, Set(String)).new

  # Add a single value to the filters on the given key. If there are already
  # some filters on this key, the original values are kept as well.
  def add(key : String, value : String) : Nil
    self[key] = Set{value} unless self[key]?.try { |set| set << value }
  end

  delegate :[], :[]=, :[]?, :&, :has_key?, to: @data

  # Add a series of values to the filters on the given key. If there are
  # already some filters on this key, the original values are kept as well.
  def add(key : String, values : Enumerable(String))
    if has_key? key
      self[key] &= values.to_set
    else
      self[key] = values.to_set
    end
  end

  def self.new(context : HTTP::Server::Context)
    this = new
    context.params.query.fetch_all("filter").map(&.split '=').each do |filter|
      raise InvalidFilter.new context if filter.size < 2
      this.add key: filter[0], values: filter[1..]
    end
    this
  end

  # Return true if the given package file's attributes pass the filters
  def filters_allow?(pkg_file : DPPM::Prefix::PkgFile) : Bool
    keep = true
    pkg_file.each_ivar do |key, value|
      if filter_set = self[key]?
        keep = false unless filter_set.includes? value
      end
    end
    keep
  end

  {% for type in %w(src app pkg) %}
  # build the JSON list of data from the package files of all {{type.id}}s
  # that pass the filters.
  def {{type.id}}s_json(builder : JSON::Builder, keys : Enumerable(String))
    builder.array do
      Route.prefix.each_{{type.id}} do |{{type.id}}|
        {{type.id}}.pkg_file.to_json builder, keys if filters_allow? {{type.id}}.pkg_file
      end
    end
  end
  {% end %}
end
