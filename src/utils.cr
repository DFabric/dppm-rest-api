# This defines the action to be taken by the given name under the current scope.
# For example, for the src_route :list, you would define route :list under
# SrcActions like so...
# ```
# route :list do |context|
#   # do a thing
# end
# ```
# which expands to the following method:
# ```
# def list
#   ->(context : HTTP::Server::Context) do |context|
#     # do a thing
#   end
# end
# ```
# See the various _route macros for more information.
macro route(name, &block)
  def {{name.id}} : ->(HTTP::Server::Context)
    ->(context : HTTP::Server::Context) do
      {{block.body}}
    end
  end
end

# Render the given data as JSON to the local `context` variable.
macro render_data(data)
  context.content_type = "application/json"
  IO.copy data, context
end

{% for base_action in [ :app, :pkg, :service, :src ] %}
# This defines a route -> action association. For example,
#
# ```crystal
# {{base_action.id}}_route :get, "/:some_param/route", :action
# ```
#
# Associates the proc returned from the {{base_action.capitalize.id}}Action.action
# method with the route "/dppm/{{base_action.id}}/:some_param/route", when
# received with the GET HTTP verb. The above macro expands to...
#
# ```crystal
# get "/dppm/{{base_action.id}}/:some_param/route", &DppmRestApi::Actions::{{base_action.capitalize.id}}Actions.action
# ```
# ... which kemal then uses to define the route.
macro {{base_action.id}}_route(method, route, action_name)
  \{{method.id}} "/dppm/{{base_action.id}}\{{route.id}}", &DppmRestApi::Actions::\{{base_action.capitalize.id}}Actions.\{{action_name.id}}
end
{% end %}
