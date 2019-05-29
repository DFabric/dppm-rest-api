module DppmRestApi::Actions::Pkg
  extend self
  ALL_PKGS = ""
  ONE_PKG  = "/:id"

  def output_config_for(package, to builder)
    builder.field package.package do
      builder.object do
        package.pkg_file.config_vars.try &.each_key do |key|
          builder.field key, package.get_config key
        end
      end
    end
  end

  def find_package_by_name(name) : Prefix::Pkg?
    Prefix.new(prefix).each_pkg do |pkg|
      if pkg.package == package_name
        return pkg
      end
    end
  end

  # List built packages
  relative_get nil do |context|
    if context.current_user? && Actions.has_access? context, Access::Read
      pfx = Prefix.new prefix
      # Build JSON directly to the HTTP response IO
      JSON.build context.response do |json|
        json.array do
          # build an array of all the package names
          pfx.each_pkg { |pkg| json.string pkg.package }
        end
      end
      next context
    end
    raise Unauthorized.new context
  end
  # Clean unused built packages
  relative_delete "/clean" do |context|
    if context.current_user? && Actions.has_access? context, Access::Delete
      res = Prefix.new(prefix).clean_unused_packages(confirmation: false) { }
      if result = res
        if result.empty?
          context.response.status_code = 404
          {
            errors: [
              "no packages to clean",
              "received empty set from Prefix#clean_unused_packages; please report this strange bug",
            ],
          }
        else
          result
        end
      else
        {errors: ["no packages to clean"]}
      end.to_json context.response
      context.response.flush
      next context
    end
    raise Unauthorized.new context
  end
  # Query information about a given package
  relative_get "/:id/query" do |context|
    if context.current_user? && Actions.has_access? context, Access::Read
      package_name = URI.unescape context.params.url["id"]
      # Iterate over the packages to find the relevant one.
      if selected_pkg = find_package_by_name package_name
        # The package whose name was the :id URL parameter was found and we can query it
        if key = context.params.query["get"]?
          # A key was specified by the &get query parameter
          begin
            {
              package_name => {
                key => selected_pkg.get_config key,
                # This method call  ^^ raises an untyped error if the key is not found
              },
              "errors" => [] of Nil,
            }.to_json context.response
            context.response.flush
            next context
          rescue e : Exception
            # catch the exception thown by the lack of a config value for the specified key
            # otherwise, pass it on to the
            msg = e.message || raise e
            raise e unless msg.starts_with? "config key not found"
            context.response.status_code = 404
            {errors: [e.message]}.to_json context.response
            context.response.flush
            next context
          end
        else
          # No specific key was requested, respond with all of the config options
          # for this package and all dependent packages
          JSON.build context.response do |builder|
            builder.object do
              output_config_for selected_pkg, to: builder
              if context.params.query["deps"]? && (deps = selected_pkg.pkg_file.deps)
                builder.field "dependencies" do
                  deps.each do |name, version|
                    semver = SemanticVersion.parse version
                    Prefix.new(prefix).each_pkg do |pkg|
                      if (pkg.package == name) && (pkg.semantic_version == semver)
                        output_config_for pkg, to: builder
                      end
                    end
                  end
                end
              end
            end
          end
        end
      else
        {errors: [%[no such package "#{package_name}" found]]}.to_json context.response
        context.response.flush
        context.response.status_code = 404
      end
      next context
    end
    raise Unauthorized.new context
  end
  # Delete a given package
  relative_delete "/:id/delete" do |context|
    if context.current_user? && Actions.has_access? context, Access::Delete
      package_name = URI.unescape context.params.url["id"]
      if selected_pkg = find_package_by_name package_name
        selected_pkg.delete confirmation: false { }
      else
        context.response.status_code = 404
        {errors: ["no package named #{package_name} was found"]}.to_json context.response
        context.response.flush
      end
      next context
    end
    raise Unauthorized.new context
  end
  # Build a package, returning the ID of the built image, and perhaps a status
  # message? We could also use server-side events or a websocket to provide the
  # status of this action as it occurs over the API, rather than just returning
  # a result on completion.
  relative_post "/:id/build" do |context|
    if context.current_user? && Actions.has_access? context, Access::Create
      # TODO: build the package based on the submitted configuration
    end
    raise Unauthorized.new context
  end
end
