require "../../utils"
module DppmRestApi::Actions::Service
  # List the managed services. The `system` query parameter may be specified to
  # enumerate all system services rather than just the ones managed by DPPM.
  get root_path do |context|

  end
  # List each managed service along with its status output.
  get root_path + "/status" do |context|

  end
  # start the service associated with the given application
  patch root_path + "/:service/boot" do |context|

  end
  # reload the service associated with the given application
  patch root_path + "/:service/reload" do |context|

  end
  # restart the service associated with the given application
  patch root_path + "/:service/restart" do |context|

  end
  # start the service associated with the given application
  patch root_path + "/:service/start" do |context|

  end
  # get the status of the service associated with the given application
  patch root_path + "/:service/status" do |context|

  end
  # stop the service associated with the given application
  patch root_path + "/:service/stop" do |context|

  end
end
