module DppmRestApi::Actions::Pkg
  extend self
  # List built packages
  relative_get nil do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: list all built packages
      next context
    end
    raise Unauthorized.new context
  end
  # Clean unused built packages
  relative_delete "/clean" do |context|
    if context.current_user? && Config.has_access? context, Access::Delete
      # TODO: delete all unused built packages
      next context
    end
    raise Unauthorized.new context
  end
  # Query information about a given package
  relative_get "/:id/query" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: Query information about the given package
      next context
    end
    raise Unauthorized.new context
  end
  # Delete a given package
  relative_delete "/:id/delete" do |context|
    if context.current_user? && Config.has_access? context, Access::Delete
      # TODO: Query information about the given package
      next context
    end
    raise Unauthorized.new context
  end
  # Build a package, returning the ID of the built image, and perhaps a status
  # message? We could also use server-side events or a websocket to provide the
  # status of this action as it occurs over the API, rather than just returning
  # a result on completion.
  relative_post "/:id/build" do |context|
    if context.current_user? && Config.has_access? context, Access::Create
      # TODO: build the package based on the submitted configuration
    end
    raise Unauthorized.new context
  end
end
