require "kemal"
require "./actions/*"

module DppmRestApi::Actions
  API_DOCUMENT = "#{__DIR__}/api-options.json"
  include Pkg
  include App
  include Service
  include Src

  options("/api") { |context| File.open(API_DOCUMENT) { |file| render_data file } }
end
