module DppmRestApi::Actions::Src
  extend self
  relative_get "" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: List all available source packages
      next context
    end
    deny_access! to: context
  end
  # List all available source packages, of either the *lib* or *app* type.
  relative_get "/:type" do |context|
    if context.current_user? && Config.has_access? context, Access::Read
      # TODO: List available source packages
      next context
    end
    deny_access! to: context
  end
end
