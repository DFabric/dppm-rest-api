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
            info: <<-HERE.to_s,
            edit one or more user's groups

            The users may be selected either by sepecifying a user's API key,
            if it is known, or by matching the name and groups the user is a
            member of. It is not recommended to match only by name or by groups,
            as your command may unintentionally affect similar users. For
            example, two users may choose the same name, but be members of
            different groups. This doesn't matter as they're only identified
            internally by their API keys, but you may unintentionally add/remove
            groups from those users when using this command in that situation.

            Ideally, you won't have multiple users with the same name, or you
            can use the web interface to edit these values using API keys for
            exact identification.
            HERE
            action:    "DppmRestApi::CLI.edit_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: <<-HERE.to_s,
                The groups selected users must be a member of. They may
                also be members of grousp that are not specified.
                You may specify several groups by separating them with
                commas, and multiple group selectors by separating
                them with a colon, like `match-groups=1,2,3:2,4', which
                would select a user who's a member of groups 1, 2, and
                3, or a user who's a member of groups 2 and 4.
                HERE
              },
              api_key: {
                info: "the api key to select a user by. To change a user's \
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
            info: <<-HERE.to_s,
            generate a new API key for this user/users and output that file.

            The users may be selected either by sepecifying a user's API key,
            if it is known, or by matching the name and groups the user is a
            member of. It is not recommended to match only by name or by groups,
            as your command may unintentionally affect similar users. For
            example, two users may choose the same name, but be members of
            different groups. This doesn't matter as they're only identified
            internally by their API keys, but you may unintentionally add/remove
            groups from those users when using this command in that situation.

            Ideally, you won't have multiple users with the same name, or you
            can use the web interface to edit these values using API keys for
            exact identification.
            HERE
            action:    "DppmRestApi::CLI.rekey_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: <<-HERE.to_s,
                The groups selected users must be a member of. They may
                also be members of grousp that are not specified.
                You may specify several groups by separating them with
                commas, and multiple group selectors by separating
                them with a colon, like `match-groups=1,2,3:2,4', which
                would select a user who's a member of groups 1, 2, and
                3, or a user who's a member of groups 2 and 4.
                HERE
              },
              api_key: {
                info: "the api key to select a user by.",
              },
              output_file: {
                info: "write the generated key to a file. Default is to print \
                       to stdout.",
              },
            },
          },
          delete: {
            info: <<-HERE.to_s,
            Completely delete a user or set of users.

            The users may be selected either by sepecifying a user's API key,
            if it is known, or by matching the name and groups the user is a
            member of. It is not recommended to match only by name or by groups,
            as your command may unintentionally affect similar users. For
            example, two users may choose the same name, but be members of
            different groups. This doesn't matter as they're only identified
            internally by their API keys, but you may unintentionally add/remove
            groups from those users when using this command in that situation.

            Ideally, you won't have multiple users with the same name, or you
            can use the web interface to edit these values using API keys for
            exact identification.
            HERE
            action:    "DppmRestApi::CLI.delete_users",
            variables: {
              match_name: {
                info: "the name of the users to filter by. You may use \
                      regex by surrounding the argument in slashes, like " +
                      %q<`match-name=/some-user\d{0,2}/', or just a specific name.>,
              },
              match_groups: {
                info: <<-HERE.to_s,
                The groups that selected users must be a member of. They may
                also be members of groups that are not specified. You may
                specify several groups by separating them with commas, and
                multiple group selectors by separating them with a colon,
                like `match-groups=1,2,3:2,4', which would select a user who's
                a member of groups 1, 2, and 3, or a user who's a member of
                groups 2 and 4.
                HERE
              },
              api_key: {
                info: "the api key to select a user by",
              },
            },
          },
        },
      },
    },
  }
)
