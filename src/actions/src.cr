module DppmRestApi::Actions::Src
  extend self
  include RouteHelpers

  # Lists available sources.
  relative_get do |context|
    filters = RouteHelpers::Filters.new context
    build_json context.response do |response|
      response.field "sources" do
        filters.srcs_json response, keys: context.params.query.fetch_all "return"
      end
    end
  end
end
