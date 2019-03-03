require "kemal"
require "../utils"
require "./actions/*"

module DppmRestApi::Actions
  extend self

  # This method establishes all the Kemal routes, using the macros defined in
  # the "utils.cr" file to DRY.
  def set_up_routes
    # Return a document which contains the API layout.
    options("/api") { |context| render_data File.read API_DOCUMENT }

    # These routes apply to the `/api/app/` section, and their actions can be
    # found in the `DppmRestApi::Actions::AppActions` module.

    app_route :get, "/:app_name/config/:key", :get_config
    app_route :post, "/:app_name/config/:key", :set_config
    app_route :delete, "/:app_name/config/:key", :del_config
    app_route :get, "/:app_name/config", :list_config
    {% for action in [:boot, :reload, :restart, :start, :status, :stop] %}
    app_route :patch, "/:app_name/service/{{action.id}}", :service_{{action.id}} {% end %}
    app_route :get, "/:app_name/libs", :libs
    app_route :get, "/:app_name/app", :base_package
    app_route :get, "/:app_name/pkg", :package_data
    app_route :get, "/:app_name/logs", :logs
    app_route :ws, "/:app_name/logs", :stream_logs
    app_route :patch, "/:pkg_name", :add
    app_route :delete, "/:app_name", :delete

    # These routes apply to the `/api/service/` section, and their actions can be
    # found in the `DppmRestApi::Actions::ServiceActions` module.

    get "/service", &ServiceActions.list
    service_route :get, "/status", &ServiceActions.list_status
    {% for action in [:boot, :reload, :restart, :start, :status, :stop] %}
    service_route :patch, "/:service/{{action.id}}", :{{action.id}} {% end %}

    # These routes apply to the `/api/pkg/` section, and their actions can be
    # found in the `DppmRestApi::Actions::PkgActions` module.

    get "/pkg", &PkgActions.list
    delete "/pkg", &PkgActions.clean
    pkg_route :get, "/:id/:version", :query
    pkg_route :get, "/:id", :query
    pkg_route :delete, "/:id/:version", :delete
    pkg_route :delete, "/:id", :delete
    pkg_route :post, "/build/:package/:version", :build
    pkg_route :post, "/build/:package", :build

    # These routes apply to the `/api/src/` section, and their actions can be
    # found in the `DppmRestApi::Actions::SrcActions` module.

    get "/src", &SrcActions.list
    src_route :get, "/:type", :list
  end

end
