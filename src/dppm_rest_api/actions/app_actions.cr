require "../../utils"
module DppmRestApi::Actions::AppActions
  extend self
  route :get_config do |context|

  end
  route :set_config do |context|

  end
  route :del_config do |context|

  end
  # All keys, or all config options
  route :list_config do |context|

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
  # lists dependent library packages
  route :libs do |context|

  end
  # return the base application package
  route :base_package do |context|

  end
  # returns information present in pkg.con as JSON
  route :package_data do |context|

  end
  # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
  # and stream the results. Otherwise return a JSON-formatted output of the
  # current log data.
  route :logs do |context|

  end
  # Stream the logs for the given application over the websocket connection.
  route :stream_logs do |context|

  end
  # Install the given package
  route :add do |context|

  end
  # Delete the given application
  route :delete do |context|

  end
end
