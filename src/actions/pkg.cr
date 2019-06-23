module DppmRestApi::Actions
  module Pkg
    extend self
    ALL_PKGS = ""
    ONE_PKG  = "/:id"
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

    def clean_unused_packages(context : HTTP::Server::Context)
      if result = get_prefix_or_default(from: context).clean_unused_packages(confirmation: false) { }
        return {data: result} if result.any?
        bug = InternalServerError.new context, "received empty set from Prefix#clean_unused_packages; please report this strange bug"
        error = NoPkgsToClean.new context
        error.cause = bug
        raise error
      end
      raise NoPkgsToClean.new context
    end

    # List built packages
    relative_get nil do |context|
      if Actions.has_access? context, Access::Read
        pkgs = [] of String
        begin
          get_prefix_or_default(from: context).each_pkg { |pkg| pkgs << pkg.package }
        rescue e
          raise InternalServerError.new context,
            message: "#each_pkg raised an exception with the message '#{e.message}'.",
            cause: e
        end
        {data: pkgs}.to_json context.response
        context.response.flush
        next context
      end
      raise Unauthorized.new context
    end
    # Clean unused built packages
    relative_delete "/clean" do |context|
      if Actions.has_access? context, Access::Delete
        clean_unused_packages(context).to_json context.response
        context.response.flush
        next context
      end
      raise Unauthorized.new context
    end
    # Query information about a given package
    relative_get "/:id/query" do |context|
      if Actions.has_access? context, Access::Read
        package_name = URI.unescape context.params.url["id"]
        version = context.params.query["version"]?.try { |v| URI.unescape v }
        # Iterate over the packages to find the relevant one.
        selected_pkg = get_prefix_or_default(from: context).new_pkg package_name, version
        raise NoSuchPackage.new context, package_name unless selected_pkg.exists?
        # Stop here ^^ unless the package whose name was the :id URL parameter
        # was found and we can query it
        if key = context.params.query["get"]?
          data = begin
            selected_pkg.get_config key
          rescue error : ConfigKeyError
            raise NotFound.new context, cause: error
          end
          # A key was specified by the &get query parameter
          build_json context.response do |json|
            json.field package_name do
              json.object do
                json.field key, value: data
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
        next context
      end
      raise Unauthorized.new context
    end
    # Delete a given package
    relative_delete "/:id/delete" do |context|
      if Actions.has_access? context, Access::Delete
        package_name = URI.unescape context.params.url["id"]
        selected_pkg = get_prefix_or_default(from: context).new_pkg package_name,
          context.params.query["version"]?
        raise NoSuchPackage.new context, package_name if selected_pkg.nil?
        selected_pkg.delete confirmation: false { }
        build_json context.response do |json|
          json.field "status", "successfully deleted '#{package_name}'"
        end
        next context
      end
      raise Unauthorized.new context
    end

    # Build a package, returning the ID of the built image, and perhaps a status
    # message? We could also use server-side events or a websocket to provide the
    # status of this action as it occurs over the API, rather than just returning
    # a result on completion.
    #
    # This route takes the optional query parameters "version" and "tag".
    relative_post "/:id/build" do |context|
      if Actions.has_access? context, Access::Create
        package_name = URI.unescape context.params.url["id"]
        pfx = get_prefix_or_default(from: context)
        pfx.update
        pkg = pfx.new_pkg package_name, version: context.params.query["version"]?
        pkg.build confirmation: false { }
        build_json context.response do |json|
          json.field "status", "built package #{pkg.package}:#{pkg.version} successfully"
        end
        next context
      end
      raise Unauthorized.new context
    end
  end
end
