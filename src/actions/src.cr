require "./route_filters"

module DppmRestApi::Actions::Src
  extend self
  include Route

  # Lists available sources.
  RelativeRoute.new "/src" do
    relative_get do |context|
      filters = RouteFilters.new context
      build_json_object context.response do |response|
        response.field "sources" do
          filters.srcs_json response, keys: context.params.query.fetch_all "return"
        end
      end
    end
  end
end
