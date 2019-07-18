module DppmRestApi::Actions::Src
  extend self
  include RouteHelpers

  # Lists available sources.
  relative_get do |context|
    raise Unauthorized.new context unless Actions.has_access? context, Access::Read
    JSON.build context.response do |json|
      json.object do
        json.field "data" do
          json.array do
            Actions.prefix.dppm_config.sources.each do |source_name, url|
              json.object do
                json.field "source_name", source_name
                json.field "url", url
              end
            end
          end
        end
      end
    end
  end
end
