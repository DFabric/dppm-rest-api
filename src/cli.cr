require "dppm/cli"
require "./dppm_rest_api"
require "./config/helpers"

module DppmRestApi::CLI
  extend self
  include Config::Helpers

  macro run
    DPPM::CLI.run(
      server: {
        info:      "DPPM REST API server",
        inherit:   \%w(config),
        variables: {
          data_dir: {
            info:    "data directory",
            default: DppmRestApi::Actions::DEFAULT_DATA_DIR,
          },
        },
        commands: {
          run: {
            info:      "Run the server",
            action:    "DppmRestApi::CLI.run_server",
            inherit:   \%w(config data_dir),
            variables: {
              host: {
                info:    "host to listen",
                default: DPPM::Prefix.default_dppm_config.host,
              },
              port: {
                info:    "port to bind",
                default: DPPM::Prefix.default_dppm_config.port,
              },
            },
          },
          user: {
            alias:     'u',
            info:      "Update or delete users",
            inherit:   \%w(data_dir),
            variables: {
              user_id: {
                info: "a users's UUID"
              }
            },
            commands: {
              add: {
                alias:     'a',
                info:      "Add a user",
                action:    "DppmRestApi::CLI.add_user",
                inherit:   \%w(data_dir),
                variables: {
                  name: {
                    info: "Human-readable name of the user; use quotes if you want" +
                          %<to have spaces in the name, like name="Scott Boggs">,
                  },
                  groups: {
                    info: "Comma-separated list of group IDs for which the user \
                            should have access",
                  },
                  output_file: {
                    info: "the file to output the user's generated API key to (STDOUT if not specified)",
                  },
                },
              },
              delete: {
                alias:   'd',
                info:    "Completely delete a user or set of users",
                action:  "DppmRestApi::CLI.delete_users",
                inherit: \%w(data_dir user_id),
              },
              edit: {
                alias:     'e',
                info:      "Edit one or more user's groups",
                action:    "DppmRestApi::CLI.edit_users",
                inherit:   \%w(data_dir user_id),
                variables: {
                  new_name: {
                    info: "The name to change the selected user's name to",
                  },
                  add_groups: {
                    info: "Comma-separated groups to add to the selected users",
                  },
                  remove_groups: {
                    info: "Comma-separated groups to remove from the selected users.",
                  },
                },
              },
              rekey: {
                alias:     'r',
                info:      "Generate a new API key for this user/users and output that file",
                action:    "DppmRestApi::CLI.rekey_users",
                inherit:   \%w(data_dir user_id),
                variables: {
                  output_file: {
                    info: "Write the generated key to a file. Default is to print to stdout",
                  },
                },
              },
              show: {
                alias:     's',
                info:      "Show the available information about a user",
                action:    "DppmRestApi::CLI.show_users",
                inherit:   \%w(data_dir),
                variables: {
                  match_name: {
                    info: "The name of the users to filter by",
                  },
                  match_groups: {
                    info: "The groups that selected users must be a member of",
                  },
                  api_key: {
                    info: "The api key to select a user by. To change a user's \
                            API key that you already know, use the rekey command",
                  },
                  output_file: {
                    info: "The file to write the userdata to; defaults to stdout",
                  }
                },
              },
            },
          },
          group: {
            alias:     'g',
            info:      "Add, update, or delete groups",
            inherit:   \%w(data_dir),
            variables: {
              id: {
                info: "The ID of the group to work with",
              },
            },
            commands: {
              add: {
                alias:     'a',
                info:      "Add a group",
                action:    "DppmRestApi::CLI.add_group",
                inherit:   \%w(id data_dir name permissions),
                variables: {
                  name: {
                    info: "A short description of this group",
                  },
                  permissions: {
                    info: "\
                      JSON-formatted permissions, mapping a path to the query \
                      parameters and type of access allowed on that path",
                    default: DppmRestApi::Config::Group::DEFAULT_PERMISSIONS.to_json,
                  },
                },
              },
              add_route: {
                alias:     "ar",
                info:      "Add permissions to a route",
                action:    "DppmRestApi::CLI.add_route",
                inherit:   \%w(id data_dir),
                variables: {
                  path: {
                    info: "The path glob on which you want to add the permissions",
                  },
                  access: {
                    info: "the kinds of access to allow on this path",
                  },
                },
              },
              delete: {
                alias:  'd',
                info:   "Delete the given group from the system",
                action: "DppmRestApi::CLI.delete_group",
                inherit:   \%w(id data_dir),
              },
              edit_access: {
                alias:     "ea",
                info:      "Change a group's permissions",
                action:    "DppmRestApi::CLI.edit_access",
                inherit:   \%w(id data_dir),
                variables: {
                  path: {
                    info: "The path on which to update permissions",
                  },
                  access: {
                    info: "The access level to give this group on the given path",
                  },
                },
              },
              edit_query: {
                alias:     "eq",
                info:      "Update the allowed query parameters on this path",
                action:    "DppmRestApi::CLI.edit_group_query",
                inherit:   \%w(id data_dir),
                variables: {
                  path: {
                    info: "The path on which to update allowed query parameters.",
                  },
                  key: {
                    info: "the query key to match for",
                  },
                  add_glob: {
                    info: "A glob to add to the allowed globs on this path",
                  },
                  remove_glob: {
                    info:  "A glob to remove from the allowed globs on this path",
                  },
                },
              },
            },
          },
        },
      }
    )
  end

  # All variables are received by a method as a `String | Nil`. This macro
  # converts an argument, by name, to its `String` value, or raises an
  # error instructing the user to include the variable value.
  private macro required(*args)
    {% for arg in args %}
    {{arg.id}} || raise RequiredArgument.new "{{arg.id}}"
    {% end %}
  end

  def run_server(config, host, port, data_dir)
    if port.is_a? String
      port = port.to_i
    end
    if config
      dppm_config = DPPM::Prefix::Config.new File.read config
      port ||= dppm_config.port
      host ||= dppm_config.host
    end
    DppmRestApi.run host, port, data_dir
  end

  def add_user(name, groups, data_dir, output_file) : Nil
    required data_dir, groups, name
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    using_stdout = true
    output_io = if output_file
                  using_stdout = false
                  File.open output_file, mode: "w"
                else
                  STDOUT
                end
    group_list = split_numbers groups
    api_key, user = DppmRestApi::Config::User.create group_list, name
    output_io.puts "API key for user named '#{name}'"
    output_io.puts api_key
    if using_stdout
      DPPM::CLI.confirm_prompt { raise "cancelled" }
    else
      output_io.close
    end
    current_config.users << user
    current_config.write_to permissions_file
  end

  def edit_users(user_id, new_name, add_groups, remove_groups, data_dir)
    required data_dir, user_id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    user_index = current_config.users.index { |usr| usr.id == user_id }
    raise "no user found with id #{user_id}" if user_index.nil?
    user = current_config.users[user_index]
    # edit the user based on the non-nil arguments given by the user
    new_name.try do |specified_new_name|
      user.name = specified_new_name
    end
    add_groups.try do |groups_to_add|
      split_numbers groups_to_add do |id|
        user.join_group id
      end
    end
    remove_groups.try do |groups_to_remove|
      split_numbers groups_to_remove do |id|
        user.leave_group id
      end
    end
    current_config.users[user_index] = user
    current_config.write_to permissions_file
  end

  def rekey_users(user_id, data_dir, output_file)
    required data_dir, user_id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    using_stdout = true
    output_io = if o = output_file
                  using_stdout = false
                  File.open o, mode: "w"
                else
                  STDOUT
                end

    user_index = current_config.users.index { |user| user.id == user_id }
    raise "no user found with id #{user_id}" if user_index.nil?
    user = current_config.users[user_index]
    # Rekey the users that have made it through the filters
    new_key = Random::Secure.base64 24
    output_io.puts "user named #{user.name} who has access to the \
                      groups #{current_config.group_view(user).groups} is now accessible via API key:"
    output_io.puts new_key
    user.api_key_hash = Scrypt::Password.create new_key
    output_io.close unless using_stdout
    current_config.users[user_index] = user
    current_config.write_to permissions_file
  end

  def delete_users(user_id, data_dir)
    required data_dir, user_id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    current_config.users.reject! { |user| user.id == user_id }
    current_config.write_to permissions_file
  end

  def show_users(data_dir, match_name, match_groups, api_key, output_file)
    required data_dir
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    using_stdout = true
    output_io = if o = output_file
                  using_stdout = false
                  File.open o, mode: "w"
                else
                  STDOUT
                end
    JSON.build output_io, indent: 2 do |builder|
      # TODO: Exclude password hashes
      selected_users(
        match_name, match_groups, api_key, from: current_config.users
      ).to_json builder
    end
    output_io.puts
    output_io.close unless using_stdout
  end

  def add_group(id, name, permissions, data_dir)
    required id, name, permissions, data_dir
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    id_number = id.to_i? || abort "failed to convert group ID #{id} to an integer"
    raise "a group with the id #{id} already exists" if current_config
                                                          .groups.map(&.id).includes? id
    perms = Hash(String, DppmRestApi::Config::Route).from_json permissions
    new_group = DppmRestApi::Config::Group.new name, id_number, perms
    current_config.groups << new_group
    current_config.write_to permissions_file
  end

  def edit_access(id, path, access, data_dir)
    required id, path, access, data_dir
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    id_number = id.to_i? || raise InvalidGroupID.new id
    group = current_config.groups.find do |grp|
      grp.id == id_number
    end
    group || raise NoSuchGroup.new id_number
    current_config.groups.delete group
    parsed_access = Access.parse?(access) ||
                    Access.from_value access.to_i? ||
                                      raise InvalidAccessParam.new access
    original_cfg = group.permissions[path]? || Config::Route.new parsed_access
    original_cfg.permissions = parsed_access
    group.permissions[path] = original_cfg
    current_config.groups << group
    current_config.write_to permissions_file
  end

  def add_route(id, access, path, data_dir)
    required id, path, access, data_dir
    group_id_number = id.to_i? || raise InvalidGroupID.new id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    relevant_group = current_config.groups
      .find { |grp| grp.id == group_id_number } || raise NoSuchGroup.new group_id_number
    parsed_access = DppmRestApi::Access.parse access
    route = DppmRestApi::Config::Route.new parsed_access
    relevant_group.permissions[path] = route
    current_config.write_to permissions_file
  end

  def edit_group_query(id, key, add_glob, remove_glob, path, data_dir)
    required id, key, path, data_dir
    group_id_number = id.to_i? || raise InvalidGroupID.new id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    relevant_group = current_config.groups.find { |grp| grp.id == group_id_number }
    relevant_group || raise NoSuchGroup.new group_id_number
    if glob_to_add = add_glob
      if route = relevant_group.permissions[path]?
        if route.query_parameters[key]?
          relevant_group.permissions[path].query_parameters[key] << glob_to_add
        else
          relevant_group.permissions[path].query_parameters[key] = [glob_to_add]
        end
      else
        raise NoRouteMatchForThisGroup.new path, group_id_number
      end
    end
    if glob_to_rm = remove_glob
      relevant_group.permissions[path].query_parameters[key].delete glob_to_rm
      if relevant_group.permissions[path].query_parameters[key].empty?
        relevant_group.permissions[path].query_parameters.delete key
      end
    end
    current_config.write_to permissions_file
  end

  def delete_group(id, data_dir)
    required id, data_dir
    group_id_number = id.to_i? || raise InvalidGroupID.new id
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    current_config.groups.reject! { |group| group.id == group_id_number }
    current_config.write_to permissions_file
  end
end
