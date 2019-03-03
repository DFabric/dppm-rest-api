require "../../utils"
module DppmRestApi::Actions::ServiceActions
  # List the managed services. The `system` query parameter may be specified to
  # enumerate all system services rather than just the ones managed by DPPM.
  route :list do |context|

  end
  # List each managed service along with its status output.
  route :list_status do |context|

  end

  # start the service associated with the given application
  route :service_boot do |context|

  end
  # reload the service associated with the given application
  route :service_reload do |context|

  end
  # restart the service associated with the given application
  route :service_restart do |context|

  end
  # start the service associated with the given application
  route :service_start do |context|

  end
  # get the status of the service associated with the given application
  route :service_status do |context|

  end
  # stop the service associated with the given application
  route :service_stop do |context|

  end
end
