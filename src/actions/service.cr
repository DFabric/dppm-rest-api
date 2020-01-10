module DppmRestApi::Actions::Service
  extend self
  include RouteHelpers
  # List the managed services. The `system` query parameter may be specified to
  # enumerate all system services rather than just the ones managed by DPPM.
  relative_get do |context|
    Actions.has_access? context, Access::Read
  end
  # List each managed service along with its status output.
  relative_get "/status" do |context|
    Actions.has_access? context, Access::Read
  end
  # start the service associated with the given application
  relative_put "/:service/boot" do |context|
    Actions.has_access? context, Access::Update
  end
  # reload the service associated with the given application
  relative_put "/:service/reload" do |context|
    Actions.has_access? context, Access::Update
  end
  # restart the service associated with the given application
  relative_put "/:service/restart" do |context|
    Actions.has_access? context, Access::Update
  end
  # start the service associated with the given application
  relative_put "/:service/start" do |context|
    Actions.has_access? context, Access::Update
  end
  # get the status of the service associated with the given application
  relative_get "/:service/status" do |context|
    Actions.has_access? context, Access::Read
  end
  # stop the service associated with the given application
  relative_put "/:service/stop" do |context|
    Actions.has_access? context, Access::Update
  end
end
