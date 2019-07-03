module DppmRestApi::Actions::Groups
  relative_post nil do |context|
    if Actions.has_access? context, Access::Create
      # TODO: create a group based on the response body
    end
    raise Unauthorized.new context
  end
  relative_put "/:id/route" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: add a new route to the group
    end
    raise Unauthorized.new context
  end
  relative_put "/:id/param" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: add a new param to the group
    end
    raise Unauthorized.new context
  end
  relative_delete "/:id/param" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: remove the given param from the group
    end
    raise Unauthorized.new context
  end
  relative_delete "/:id/route" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: remove the given route from the group
    end
    raise Unauthorized.new context
  end
  relative_delete "/:id" do |context|
    if Actions.has_access? context, Access::Update
      # TODO: remove the given group
    end
    raise Unauthorized.new context
  end
end
