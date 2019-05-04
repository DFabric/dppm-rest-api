module DppmRestApi::Actions::Pkg
  extend self
  ALL_PKGS = ""
  ONE_PKG  = "/:id"
  # List built packages
  relative_get ALL_PKGS do |context|
    if context.current_user? && has_access? context, Access::Read
      # TODO: list all built packages
      next context
    end
    deny_access! to: context
  end
  # Clean unused built packages
  relative_delete ALL_PKGS do |context|
    if context.current_user? && has_access? context, Access::Delete
      # TODO: delete all unused built packages
      next context
    end
    deny_access! to: context
  end
  # Query information about a given package
  relative_get ONE_PKG do |context|
    if context.current_user? && has_access? context, Access::Read
      # TODO: Query information about the given package
      next context
    end
    deny_access! to: context
  end
  # Delete a given package
  relative_delete ONE_PKG do |context|
    if context.current_user? && has_access? context, Access::Delete
      # TODO: Query information about the given package
      next context
    end
    deny_access! to: context
  end

  module Build
    # Build a package, returning the ID of the built image, and perhaps a status
    # message? We could also use server-side events or a websocket to provide the
    # status of this action as it occurs over the API, rather than just returning
    # a result on completion.
    relative_post "/:package" do |context|
      pkg_id = context.params.url["package"]?
      if context.current_user? && has_access? context, Access::Create
        # TODO: build the package based on the submitted configuration
      end
      deny_access! to: context
    end
  end
end
