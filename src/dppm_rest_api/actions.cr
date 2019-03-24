require "kemal"
require "./middlewares"
require "./actions/*"

module DppmRestApi::Actions
  API_DOCUMENT = "#{__DIR__}/api-options.json"
  add_handler Actions.auth_handler

  include Pkg
  include App
  include Service
  include Src

  options("/api") { |context| File.open(API_DOCUMENT) { |file| render_data file } }


  Kemal.run port: DppmRestApi.config.port.to_i
end
