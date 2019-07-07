module DppmRestApi::Actions::Service
  extend self
  include RouteHelpers
  # List the managed services. The `system` query parameter may be specified to
  # enumerate all system services rather than just the ones managed by DPPM.
  relative_get do |context|
    if Actions.has_access? context, Access::Read
      next context
    end
    raise Unauthorized.new context
  end
  # List each managed service along with its status output.
  relative_get "/status" do |context|
    if Actions.has_access? context, Access::Read
      next context
    end
    raise Unauthorized.new context
  end
  # start the service associated with the given application
  relative_put "/:service/boot" do |context|
    if Actions.has_access? context, Access::Update
      next context
    end
    raise Unauthorized.new context
  end
  # reload the service associated with the given application
  relative_put "/:service/reload" do |context|
    if Actions.has_access? context, Access::Update
      next context
    end
    raise Unauthorized.new context
  end
  # restart the service associated with the given application
  relative_put "/:service/restart" do |context|
    if Actions.has_access? context, Access::Update
      next context
    end
    raise Unauthorized.new context
  end
  # start the service associated with the given application
  relative_put "/:service/start" do |context|
    if Actions.has_access? context, Access::Update
      next context
    end
    raise Unauthorized.new context
  end
  # get the status of the service associated with the given application
  relative_get "/:service/status" do |context|
    if Actions.has_access? context, Access::Read
      next context
    end
    raise Unauthorized.new context
  end
  # stop the service associated with the given application
  relative_put "/:service/stop" do |context|
    if Actions.has_access? context, Access::Update
      next context
    end
    raise Unauthorized.new context
  end
end
