require "dppm/cli"
require "./dppm_rest_api"

module DppmRestApi::CLI
  extend self

  private def split_groups_arg(argument text : String) : Array(Int32)
    text.split(',').map do |g|
      if g_int = g.to_i?
        g_int
      else
        abort "\
          group ID #{g} wasn't a number, please use numeric group ids \
          separated by commas (,)."
      end
    end
  end

  private macro required(arg)
    mn_{{arg.id}} || abort "{{ arg.id.gsub /_/, "-" }} argument is required."
  end

  private def select_users(match_name, match_groups, api_key, current_config)
    selected_users = current_config.users
    # Filter by name
    if name = match_name
      if name.starts_with?('/') && name.ends_with?('/')
        name_regex = Regex.new name.lchop('/').rchop('/')
        selected_users = selected_users.select do |user|
          name_regex =~ user.name
        end
      else
        selected_users = selected_users.select do |user|
          user.name == name
        end
      end
    end
    # Filter by group membership
    if groups = match_groups
      group_matches = Set(Set(Int32)).new
      groups.split(':').each do |part|
        group_matches << split_groups_arg(part).to_set
      end
      selected_users = selected_users.select do |user|
        group_matches.any? do |group_set|
          group_set.all? do |group|
            user.group_ids.includes? group
          end
        end
      end
    end
    # filter by API key if specified.
    if key = api_key
      selected_users = selected_users.select { |user| user.api_key_hash == key }
      # freak out if multiple users were found.
      if selected_users.size > 1
        abort String.build { |msg|
          msg << "ERROR!!! Multiple users detected with the same API key!!    ERROR!!!\n"
          msg << "the following users each have the same API key. Keys MUST be unique!\n"
          selected_users.each do |user|
            msg << "Name: " << user.name << "; Member of: " << user.group_ids.join(", ") << '\n'
          end
          msg << "you must fix this immediately!"
        }
      end
    end
    selected_users
  end

  def run_server(config, host, port, data_dir, **args)
    if port.is_a? String
      port = port.to_i
    end
    if config
      dppm_config = Prefix::Config.new File.read config
      port ||= dppm_config.port
      host ||= dppm_config.host
    end
    DppmRestApi.run host, port, data_dir
  end

  def add_user(name, groups, data_dir, **args) : Void
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    api_key = Random::Secure.base64 24
    api_key_hash = Scrypt::Password.create api_key
    group_list = split_groups_arg groups.not_nil!
    current_config.users << DppmRestApi::Config::User.new api_key_hash, group_list, name.not_nil!
    current_config.write_to permissions_file
  end

  def edit_users(match_name, match_groups, api_key, new_name, add_groups, remove_groups, data_dir, **args)
    permissions_file = Path[data_dir, "permmissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    select_users(match_name, match_groups, api_key, current_config).each do |user|
      # edit the users that have made it through all the filters
      if specified_new_name = new_name
        user.name = specified_new_name
      end
      if groups_to_add = add_groups.try { |arg| split_groups_arg arg }
        groups_to_add.each { |id| user.join_group id }
      end
      if groups_to_remove = remove_groups.try { |arg| split_groups_arg arg }
        groups_to_remove.each { |id| user.leave_group id }
      end
    end
    current_config.write_to permissions_file
  end

  def rekey_users(match_name, match_groups, api_key, data_dir, output_file, **args)
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    using_stdout = true
    output_io = if o = output_file
                  using_stdout = false
                  File.open o
                else
                  STDOUT
                end
    select_users(match_name, match_groups, api_key, current_config).each do |user|
      # Rekey the users that have made it through the filters
      new_key = Random::Secure.base64 24
      output_io.puts "user named #{user.name} who has access to the \
                      groups #{user.groups} is now accessible via API key:"
      output_io.puts new_key
      user.api_key_hash = Scrypt::Password.create new_key
    end
    output_io.close unless using_stdout
    current_config.write_to permissions_file
  end

  def delete_users(match_name, match_groups, api_key, data_dir, **args)
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    selected = select_users match_name, match_groups, api_key, current_config
    current_config.users.reject! { |user| selected.includes? user }
    current_config.write_to permissions_file
  end

  def show_users(data_dir, **args)
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    JSON.build STDOUT, indent: 2 do |builder|
      current_config.users.to_json builder
    end
    puts
  end

  def add_group(id, name, permissions, data_dir, **args)
    abort "id argument is required" if id.nil?
    abort "name argument is required" if name.nil?
    abort "permissions argument is required" if permissions.nil?
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    id_number = id.not_nil!.to_i? || abort "failed to convert group ID #{id} to an integer"
    abort "a group with the id #{id} already exists" if current_config.groups
                                                          .map(&.id).includes? id
    perms = Hash(String, DppmRestApi::Config::Route).from_json permissions.not_nil!
    newgrp = DppmRestApi::Config::Group.new name.not_nil!, id_number, perms
    current_config.groups << newgrp
    current_config.write_to permissions_file
  end

  def edit_access(group_id mn_group_id, path mn_path, access mn_access, data_dir, **args)
    group_id = required :group_id
    path = required :path
    access = required :access
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    id_number = group_id.to_i? || abort "failed to convert group ID #{group_id} to an integer"
    group = current_config.groups.find do |grp|
      grp.id == id_number
    end || abort "no group found with ID number #{id_number}"
    parsed_access = Access.parse?(access) ||
                    Access.from_value access.to_i? ||
                                      abort "failed to parse access value '#{access}', \
                                            or convert it to an integer."
    group.permissions[path].permissions = parsed_access
    current_config.write_to permissions_file
  end

  def edit_group_query(group_id mn_group, key mn_key, add_glob, remove_glob, path mn_path, data_dir, **args)
    group_id = (mn_group || abort "the group-id argument is required").to_i? ||
               abort "failed to convert group ID '#{mn_group}' to an integer"
    key = mn_key || abort "the key argument is required"
    path = mn_path || abort "the path argument is required"
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    if glob_to_add = add_glob
      current_config.groups
        .find { |grp| grp.id == group_id }
        .try do |mn_grp|
          mn_grp.permissions[path].query_parameters[key] << glob_to_add
        end
    end
    if glob_to_rm = remove_glob
      current_config.groups
        .find { |grp| grp.id == group_id }
        .try do |mn_grp|
          mn_grp.permissions[path].query_parameters[key].delete glob_to_rm
        end
    end
    current_config.write_to permissions_file
  end

  def delete_group(group_id mn_group_id, data_dir, **args)
    group_id = (mn_group_id || abort "the group-id argument is required").to_i? ||
               abort "failed to convert group-id argument '#{mn_group_id}' to an integer"
    permissions_file = Path[data_dir, "permissions.json"]
    current_config = File.open permissions_file do |file|
      DppmRestApi::Config.from_json file
    end
    current_config.groups.reject! { |group| group.id == group_id }
    current_config.write_to permissions_file
  end
end

# DPPM CLI isn't namespaced yet
CLI.run(
  server: {
    info:      "DPPM REST API server",
    variables: {
      data_dir: {
        info:    "data directory",
        default: DppmRestApi::DEFAULT_DATA_DIR,
      },
    },
    commands: {
      run: {
        info:      "Run the server",
        action:    "DppmRestApi::CLI.run_server",
        variables: {
          host: {
            info:    "host to listen",
            default: Prefix.default_dppm_config.host,
          },
          port: {
            info:    "port to bind",
            default: Prefix.default_dppm_config.port,
          },
        },
      },
      user: {
        info: "\
        For the edit, rekey, show, and delete commands, the users may be selected \
        either by sepecifying a user's API key, if it is known, or by matching \
        the name and groups the user is a member of. It is not recommended to \
        match only by name or by groups, as your command may unintentionally \
        affect similar users. For example, two users may choose the same name, \
        but be members of different groups. This doesn't matter as they're \
        only identified internally by their API keys, but you may \
        unintentionally add/remove groups from those users when using this \
        command in that situation. \
        \
        Ideally, you won't have multiple users with the same name, or you \
        can use the web interface to edit these values using API keys for \
        exact identification. \
        \
        This can also be used for batch processing. For example, if you want to \
        replace one group with several more granular ones, you can add all \
        members of the old group to the new groups before deleting the old \
        group.",
        commands: {
          add: {
            info:      "add a user",
            action:    "DppmRestApi::CLI.add_user",
            variables: {
              name: {
                info: "human-readable name of the user. Use quotes if you want" +
                      %<to have spaces in the name, like name="Scott Boggs">,
              },
              groups: {
                info: "comma-separated list of group IDs for which the user \
                       should have access.",
              },
            },
          },
          edit: {
            info:      "edit one or more user's groups",
            action:    "DppmRestApi::CLI.edit_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: "The groups that selected users must be a member of. \
                       They may also be members of groups that are not \
                       specified. You may specify several groups by separating \
                       them with commas, and multiple group selectors by \
                       separating them with a colon, like \
                       `match-groups=1,2,3:2,4', which would select a user \
                       who's a member of groups 1, 2, and 3, or a user who's a \
                       member of groups 2 and 4.",
              },
              api_key: {
                short: "key",
                info:  "the api key to select a user by. To change a user's \
                       API key that you already know, use the rekey command.",
              },
              new_name:   {info: "the name to change the selected user's name to."},
              add_groups: {
                info: "comma-separated groups to add to the selected users.",
              },
              remove_groups: {
                info: "comma-separated groups to remove from the selected \
                       users. Groups that a selected user is already not a \
                       member of will be ignored.",
              },
            },
          },
          rekey: {
            info:      "generate a new API key for this user/users and output that file.",
            action:    "DppmRestApi::CLI.rekey_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: "The groups that selected users must be a member of. \
                       They may also be members of groups that are not \
                       specified. You may specify several groups by separating \
                       them with commas, and multiple group selectors by \
                       separating them with a colon, like \
                       `match-groups=1,2,3:2,4', which would select a user \
                       who's a member of groups 1, 2, and 3, or a user who's a \
                       member of groups 2 and 4.",
              },
              api_key: {
                short: "key",
                info:  "the api key to select a user by.",
              },
              output_file: {
                short: "file",
                info:  "write the generated key to a file. Default is to print \
                       to stdout.",
              },
            },
          },
          delete: {
            info:      "Completely delete a user or set of users",
            action:    "DppmRestApi::CLI.delete_users",
            alias:     "rm",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: "The groups that selected users must be a member of. \
                       They may also be members of groups that are not \
                       specified. You may specify several groups by separating \
                       them with commas, and multiple group selectors by \
                       separating them with a colon, like \
                       `match-groups=1,2,3:2,4', which would select a user \
                       who's a member of groups 1, 2, and 3, or a user who's a \
                       member of groups 2 and 4.",
              },
              api_key: {
                short: "key",
                info:  "the api key to select a user by",
              },
            },
          },
          show: {
            info:      "Show the available information about a user.",
            action:    "DppmRestApi::CLI.show_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: "The groups that selected users must be a member of. \
                       They may also be members of groups that are not \
                       specified. You may specify several groups by separating \
                       them with commas, and multiple group selectors by \
                       separating them with a colon, like \
                       `match-groups=1,2,3:2,4', which would select a user \
                       who's a member of groups 1, 2, and 3, or a user who's a \
                       member of groups 2 and 4.",
              },
              api_key: {
                short: "key",
                info:  "the api key to select a user by",
              },
            },
          },
        },
      },
      group: {
        alias:    "g",
        commands: {
          add: {
            info:      "add a group",
            alias:     "a",
            action:    "DppmRestApi::CLI.add_group",
            variables: {
              id: {
                info: "this group's ID. Defaults to a random value.",
              },
              name: {
                info: "a short description of this group",
              },
              permissions: {
                info: "\
                  JSON-formatted permissions, mapping a path to the query \
                  parameters and type of access allowed on that path.",
                default: {
                  "/**"                       => DppmRestApi::Config::Route.new(DppmRestApi::Access.deny),
                  "/{app,pkg,src,service}/**" => DppmRestApi::Config::Route.new(
                    DppmRestApi::Access::All,
                    {"namespace" => ["default-namespace"]}),
                }.to_json,
              },
            },
          },
          edit_access: {
            info:      "change a group's permissions",
            alias:     "e",
            action:    "DppmRestApi::CLI.edit_access",
            variables: {
              group_id: {
                info: "the numeric ID of the group to edit",
              },
              path: {
                info: "The path on which to update permissions.",
              },
              access: {
                info: "the access level to give this group on the given path",
              },
            },
          },
          edit_query: {
            info:      "update the allowed query parameters on this path",
            alias:     "q",
            action:    "DppmRestApi::CLI.edit_group_query",
            variables: {
              group_id: {
                info: "the numeric ID of the group to edit",
              },
              path: {
                info: "the path on which to update allowed query parameters.",
              },
              key:      {info: "the query key to match for"},
              add_glob: {
                short: "add",
                info:  "a glob to add to the allowed globs on this path.",
              },
              remove_glob: {
                short: "rm",
                info:  "\
                    a glob to remove from the allowed globs on this path.",
              },
            },
          },
          delete: {
            info:      "delete the given group from the system.",
            alias:     "rm",
            action:    "DppmRestApi::CLI.delete_group",
            variables: {
              group_id: {info: "the ID of the group to remove"},
            },
          },
        },
      },
    },
  }
)
