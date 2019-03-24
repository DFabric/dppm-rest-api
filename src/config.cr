require "./config/*"
require "json"

class DppmRestApi::Config
  module Defaults
    extend self

    def file_loc : String
      conf_dir = if confdir = ENV["XDG_CONFIG_DIRS"]?
                   confdir
                 elsif home = ENV["HOME"]?
                   ::File.join home, ".config"
                 else
                   "/root/.config"
                 end
      ::File.join conf_dir, "dppm", "server.con"
    end

    def host : String
      ENV["HOST"]? || "127.0.0.1"
    end

    def port : UInt16
      (ENV["PORT"]?.try &.to_i || 3000).to_u16
    end

    def public_host : String?
      ENV["PUBLIC_HOST"]?
    end
  end

  # The location of the config file
  property file_loc : String
  # The hostname of this server
  property host : String
  # The port the server will listen on
  property port : UInt16
  # The publicly accessible hostname of this server, if different. This is for
  # if the server is being published behind a reverse proxy.
  property public_host : String?
  property file : Config::File

  def initialize(@file_loc,
                 @host = Defaults.host,
                 @port = Defaults.port,
                 @public_host = Defaults.public_host)
    @file = ::File.open @file_loc do |data|
      Config::File.from_json data
    end
  end

  def self.from_args(args = ARGV)
    file_loc = nil
    host = nil
    port = nil
    public_host = nil
    OptionParser.parse args do |op|
      op.on("--file_loc", "The location of the config file") { |v| file_loc = v }
      op.on("--host", "The hostname of this server") { |v| host = v }
      op.on("--port", "The port the server will listen on") { |v| port = v.to_u16 }
      op.on "--public_host", "The publicly accessible hostname of this server, if different. This is for if the server is being published behind a reverse proxy" do |v|
        public_host = v
      end
    end

    new (file_loc || Defaults.file_loc).not_nil!, (host || Defaults.host).not_nil!, (port || Defaults.port).not_nil!, public_host
  end
end
