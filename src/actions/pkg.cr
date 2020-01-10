module DppmRestApi::Actions::Pkg
  extend self
  include RouteHelpers

  def build_config_response(package, builder)
    builder.field package.package do
      builder.object do
        package.each_config_key do |key|
          builder.field key, package.get_config key
        end
      end
    end
  end

  # List built packages
  #
  # TODO optional pagination
  relative_get "/:source_name" do |context|
    Actions.has_access? context, Access::Read
    prefix = get_prefix_with_source_name context
    JSON.build context.response do |json|
      json.object do
        json.field "data" do
          json.array do
            prefix.each_pkg do |package|
              json.object do
                json.field "package", package.package
                json.field "version", package.version
              end
            end
          end
        end
      end
    end
  end

  # Clean unused built packages
  relative_delete "/:source_name/clean" do |context|
    Actions.has_access? context, Access::Delete
    prefix = get_prefix_with_source_name context
    result = prefix.clean_unused_packages(confirmation: false) { }
    if result.empty?
      raise NoPkgsToClean.new context
    else
      {data: result}.to_json(context.response)
      context.response.flush
    end
  end
  # Query information about a given package
  relative_get "/:source_name/:package_name/query" do |context|
    Actions.has_access? context, Access::Read
    prefix = get_prefix_with_source_name context
    package_name = URI.decode context.params.url["package_name"]

    version = context.params.query["version"]?.try { |v| URI.decode v }
    # Iterate over the packages to find the relevant one.
    selected_pkg = prefix.new_pkg package_name, version
    raise NoSuchPackage.new context, package_name unless selected_pkg.exists?
    # Stop here ^^ unless the package whose name was the :id URL parameter
    # was found and we can query it
    if key = context.params.query["get"]?
      config_value = selected_pkg.get_config? key
      raise ConfigKeyNotFound.new context, key, package_name if config_value.nil?
      # A key was specified by the &get query parameter
      build_json context.response do |json|
        json.field package_name do
          json.object do
            json.field key, value: config_value
          end
        end
      end
      next context
    else
      # No specific key was requested, respond with all of the config
      # options for this package. Additionally, respond with all
      # dependent packages if the "libraries" boolean query parameter
      # is specified.
      build_json context.response do |builder|
        build_config_response selected_pkg, builder
        if parse_boolean_param("libraries", from: context) &&
           (libs = selected_pkg.libs)
          builder.field "libraries" do
            libs.each { |pkg| build_config_response pkg, builder }
          end
        end
      end
    end
  end
  # Delete a given package
  relative_delete "/:source_name/:package_name/delete" do |context|
    Actions.has_access? context, Access::Delete
    prefix = get_prefix_with_source_name context
    package_name = URI.decode context.params.url["package_name"]
    selected_pkg = prefix.new_pkg package_name,
      context.params.query["version"]?.try { |v| URI.decode v }
    raise NoSuchPackage.new context, package_name if selected_pkg.nil?
    selected_pkg.delete confirmation: false { }
    build_json context.response do |json|
      json.field "status", "successfully deleted '#{package_name}'"
    end
  end

  # Build a package, returning the ID of the built image, and perhaps a status
  # message? We could also use server-side events or a websocket to provide the
  # status of this action as it occurs over the API, rather than just returning
  # a result on completion.
  #
  # This route takes the optional query parameters "version" and "tag".
  relative_post "/:source_name/:package_name/build" do |context|
    Actions.has_access? context, Access::Create
    package_name = URI.decode context.params.url["package_name"]
    prefix = get_prefix_with_source_name context

    init_done = false
    begin
      pkg = prefix.new_pkg package_name, version: context.params.query["version"]?
      pkg.build confirmation: false { init_done = true }
    rescue ex
      raise InternalServerError.new context, cause: ex if init_done
      raise BadRequest.new context, cause: ex
    end
    build_json context.response do |json|
      json.field "status", "built package #{pkg.package}:#{pkg.version} successfully"
    end
  end
end
