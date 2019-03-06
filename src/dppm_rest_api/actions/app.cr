require "../../utils"

module DppmRestApi::Actions::App
  extend self
  get root_path + "/:app_name/config/:key" do |context|
  end
  post root_path + "/:app_name/config/:key" do |context|
  end
  delete root_path + "/:app_name/config/:keys" do |context|
  end
  # All keys, or all config options
  get root_path + "/:app_name/config" do |context|
  end
  # start the service associated with the given application
  patch root_path + "/:app_name/service/boot" do |context|
  end
  # reload the service associated with the given application
  patch root_path + "/:app_name/service/reload" do |context|
  end
  # restart the service associated with the given application
  patch root_path + "/:app_name/service/restart" do |context|
  end
  # start the service associated with the given application
  patch root_path + "/:app_name/service/start" do |context|
  end
  # get the status of the service associated with the given application
  patch root_path + "/:app_name/service/status" do |context|
  end
  # stop the service associated with the given application
  patch root_path + "/:app_name/service/stop" do |context|
  end
  # lists dependent library packages
  get root_path + "/:app_name/libs" do |context|
  end
  # return the base application package
  get root_path + "/:app_name/app" do |context|
  end
  # returns information present in pkg.con as JSON
  get root_path + "/:app_name/pkg" do |context|
  end
  # if the `"stream"` query parameter is set, attempt to upgrade to a websocket
  # and stream the results. Otherwise return a JSON-formatted output of the
  # current log data.
  get root_path + "/:app_name/logs" do |context|
  end
  # Stream the logs for the given application over the websocket connection.
  ws root_path + "/:app_name/logs" do |context|
  end
  # Install the given package
  patch root_path + "/:package_name" do |context|
  end
  # Delete the given application
  delete root_path + "/:app_name" do |context|
  end
end
