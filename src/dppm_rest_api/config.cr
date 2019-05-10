require "./config/*"
require "../ext/scrypt"
require "json"
require "logger"

struct DppmRestApi::Config
  module Defaults
    extend self

    def file_loc : String
      {% if env("KEMAL_ENV") == "test" %}
        puts "test env"
        # Override default in the case of specs
        return Fixtures::Config
      {% end %}
      conf_dir = if confdir = ENV["XDG_CONFIG_HOME"]?
                   confdir
                 elsif home = ENV["HOME"]?
                   ::File.join home, ".config"
                 else
                   {% if flag? :unix %}
                    "/etc"
                  {% elsif flag? :win32 %}
                    raise "win32 default config location is not yet implemented. As a workaround, set the config location manually."
                  {% else %}
                    raise "unrecognized operating system. Please raise an issue on Github. As a workaround, you can set the configuration manually."
                  {% end %}
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

    def default_namespace : String
      ENV["DEFAULT_NAMESPACE"]? || "default_namespace"
    end

    def log_file : IO
      STDOUT
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
  property default_namespace : String
  property log_file : IO
  property logger : Logger { Logger.new log_file }

  def initialize(@file_loc,
                 @host = Defaults.host,
                 @port = Defaults.port,
                 @public_host = Defaults.public_host,
                 @default_namespace = Defaults.default_namespace,
                 @log_file = Defaults.log_file)
    @file = ::File.open @file_loc do |data|
      Config::File.from_json data
    end
  end

  # This needs to go away anyway.
  # ameba:disable CyclomaticComplexity
  def self.from_args(args = ARGV)
    file_loc = nil
    host = nil
    port = nil
    public_host = nil
    default_namespace = nil
    log_file = nil
    while arg = args.shift?
      case arg
      # long options
      when .starts_with? "--file-loc"
        file_loc = if arg[11]? == '='
                     arg[11..-1]
                   else
                     args.shift
                   end
      when .starts_with? "--host"
        host = if arg[7]? == '='
                 arg[7..-1]
               else
                 args.shift
               end
      when .starts_with? "--port"
        port = if arg[7]? == '='
                 arg[7..-1]
               else
                 args.shift
               end.to_u16
      when .starts_with? "--public-host"
        public_host = if arg[14]? == '='
                        arg[14..-1]
                      else
                        args.shift
                      end
      when .starts_with? "--log-file"
        log_file_loc = if arg[11]? == '='
                         arg[11..-1]
                       else
                         args.shift
                       end
        log_file = ::File.open log_file_loc, mode: "w"
      when .starts_with? "--default-namespace"
        default_namespace = if arg[20]? == '='
                              arg[20..-1]
                            else
                              args.shift
                            end
      else
        puts "unrecognized argument #{arg}"
      end
    end

    new (file_loc || Defaults.file_loc).not_nil!,
      (host || Defaults.host).not_nil!,
      (port || Defaults.port).not_nil!,
      (public_host || Defaults.public_host), # may be nil
      (default_namespace || Defaults.default_namespace).not_nil!,
      (log_file || Defaults.log_file).not_nil!
  end
end
