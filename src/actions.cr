require "kemal"
require "./utils"
require "./middlewares"
require "./actions/*"

module DppmRestApi::Actions
  include Pkg
  include App
  include Service
  include Src

  relative_options "/api" do |context|
    File.open API_DOCUMENT do |file|
      context.response.content_type = "application/json"
      IO.copy file, context.response
    end
  end

  def self.throw_error(context : HTTP::Server::Context,
                       message : String,
                       status_code = 500)
    context.response.status_code = status_code
    context.response.printf message + '\n'
    context.response.flush
    context
  end
end
