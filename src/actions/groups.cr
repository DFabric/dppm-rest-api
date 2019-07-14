module DppmRestApi::Actions::Groups
  extend self
  include RouteHelpers
  relative_post do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Create
    # TODO: create a group based on the response body

  end
  relative_put "/:id/route" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    # TODO: add a new route to the group

  end
  relative_put "/:id/param" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    # TODO: add a new param to the group

  end
  relative_delete "/:id/param" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    # TODO: remove the given param from the group

  end
  relative_delete "/:id/route" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    # TODO: remove the given route from the group

  end
  relative_delete "/:id" do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Update
    # TODO: remove the given group

  end
end
