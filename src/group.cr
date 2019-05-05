require "./access"
require "./route"

# A group represents an access role that a user may be a member of.
struct DppmRestApi::Group
  include JSON::Serializable
  include JSON::Serializable::Strict
  # The human-readable name of the `Group`. This *should* be unique.
  property name : String
  # The identifier used to refer to this `Group`. This *must* be unique.
  property id : Int32
  # All route-matching globs associated with this `Group`, mapped to the
  # group's permission level.
  property permissions : Hash(String, Route)

  # returns true if members of this group may access a request on the given
  # route, with the given permission level.
  def can_access?(path : String, query : HTTP::Params, requested_permissions : Access) : Bool
    maybe_nil_perms = permissions
      .find do |pattern, route|
        # Find the first route that matches both the path glob and the query list
        File.match?(pattern, path) && route.match? query
      end
      .try { |_, route| route.permissions }
    if configured_permissions = maybe_nil_perms
      # If the "flag is set" this will return true, otherwise it will return
      # false
      return configured_permissions.includes? requested_permissions
    end
    false
  end

  def initialize(@name, @id, @permissions); end

  @@counter = 0

  def self.new(name)
    new name, (@@counter += 1), DEFAULT_PERMISSIONS
  end

  DEFAULT_PERMISSIONS = {Route.new("/**") => Access.deny}
end
