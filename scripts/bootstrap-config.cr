module RandomID
  extend self
  property canned_cfg_ids = [] of Int32

  def new
    canned_cfg_ids << if canned_cfg_ids.includes?(new_random = Random::Secure.next Int32)
      random_id
    else
      new_random
    end
  end
end

CANNED_CONFIGS = {
  "super user (access to everything)" => DppmRestApi::Config::Group.new(
    name: "super user",
    permissions: {
      "/**" => DppmRestApi::Config::Route.new(
        permissions: DppmRestApi::Access.super_user),
    },
    id: RandomId.new
  ),
  "full access to default namespace" => DppmRestApi::Config::Group.new(
    name: "default-namespace READ access",
    id: RandomId.new,
    permissions: {
      "/**" => DppmRestApi::Config::Route.new(
        permissions: DppmRestApi::Access.super_user,
        query_parameters: {"namespace" => ["default-namespace"]}
      ),
    }
  ),
  "provide each user with a namespace named after themselves" => ->(user : DppmRestApi::Config::User) do
    DppmRestApi::Config::Group.new(
      name: user.name + "-space",
      id: RandomID.new,
      permissions: {
        "/**" => DppmRestApi::Config::Route.new(
          permissions: DppmRestApi::Access.super_user,
          query_parameters: {"namespace" => [user.name + "-space"]}
        ),
      }
    )
  end,
}

module BC
  extend self

  private def find_editor_by_path : String
    if (nano = `which nano`).empty?
      if (vim = `which vim`).empty?
        if (vi = `which vi`).empty?
          raise <<-HERE
          Could not find a text editor on this system. Checked for: $VISUAL,
          $EDITOR, `nano`, `vim`, and `vi`.
          HERE
        else
          vi
        end
      else
        vim
      end
    else
      nano
    end
  end

  def run
    tmp_file = File.tempfile do |file|
      file << "# allow or deny pre-canned config options"
      CANNED_CONFIGS.each do |title, _|
        file << "deny\t" << title
      end
      file << <<-HERE
      # Anything after a hash (#) symbol is ignored. By default, all of the
      # canned configs are turned off (deny). In order to use a canned config
      # change the word "deny" to "allow". Be sure to leave a tab character
      # between the "deny" or "allow" and the description of the group.
      #
      # If you have some configurations you'd like to import, you can do so
      # here as well. A line may contain a tab-separated group description and
      # filepath. The filepath should lead to a JSON-formatted group object.
      # In addition, you may place a JSON-formatted mapping of group
      # descriptions to (properly-formatted) group options.
      #
      # This is meant primarily as an import/export function. You should
      # probably use the command line or web interface to add new users or to
      # change user settings.
      HERE
    end
    editor = ENV["VISUAL"]? || ENV["EDITOR"]? || find_editor_by_path
    Process.run editor + ' ' + tmp_file.path
    groups = [] of Group
    File.open temp_file.path do |file|
      file.each_line chomp: true do |line|
        next if line.starts_with? '#'
        if line.starts_with?("allow\t")
          if (cfg = CANNED_CONFIGS[line.lchop "allow\t"]?).is_a? DppmRestApi::Config::Group
            groups << cfg
          elsif !cfg.nil?
          end
        end
      end
    end
    temp_file.delete
  end
end
