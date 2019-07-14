module DppmRestApi::Actions::Users
  include RouteHelpers
  extend self
  relative_put do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Create
    # TODO: apply an edit to a batch of users

  end
  relative_delete do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Delete
    # TODO: delete a batch of users

  end
  relative_get do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Read
    # TODO: get info on a batch of users

  end
end
