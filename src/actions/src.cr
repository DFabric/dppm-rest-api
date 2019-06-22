module DppmRestApi::Actions::Src
  extend self
  include Utils
  relative_get "" do |context|
    if Actions.has_access? context, Access::Read
      # TODO: List all available source packages
      next context
    end
    raise Unauthorized.new context
  end
  # List all available source packages, of either the *lib* or *app* type.
  relative_get "/:type" do |context|
    if Actions.has_access? context, Access::Read
      # TODO: List available source packages
      next context
    end
    raise Unauthorized.new context
  end
end
