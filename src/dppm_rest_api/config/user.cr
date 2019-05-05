require "json"

module DppmRestApi
  struct User
    API_KEY_SIZE = 63_u8
    include JSON::Serializable
    property api_key_hash : Scrypt::Password
    setter groups : Array(Int32)

    def groups : Array(Group)
      Array(Group).new.tap { |ary| each_group { |group| ary << group } }
    end

    def group_ids
      @groups
    end

    property name : String

    def initialize(@api_key_hash,
                   @groups,
                   @name); end

    def self.new(api_key_hash string : String, groups, name)
      new Scrypt::Password.new(string), groups, name
    end

    def self.create(groups : Array(Group), name : String) : {String, self}
      api_key = Random::Secure.base64 API_KEY_SIZE
      {api_key, new(Scrypt::Password.create(api_key), groups.map { |g| g.id }, name)}
    end

    def to_h : JWTCompatibleHash
      JWTCompatibleHash{"groups"       => serialized_groups,
                        "name"         => @name,
                        "API key hash" => api_key_hash.to_s}
    end

    def self.from_h(hash data : JWTCompatibleHash)
      if (groups = data["groups"]?).is_a?(String) &&
         (name = data["name"]?).is_a?(String) &&
         (key = data["API key hash"]?).is_a? String
        new key, groups.split(',').map(&.to_i), name
      end
    rescue ArgumentError
      nil
    end

    private def serialized_groups : String
      groups.map(&.id.to_s base: 16).join(",")
    end

    def self.deserialize(groups : String)
      groups.split(',').map { |id| id.to_i base: 16 }
    end

    # Yields each Group to the block for which the user is a member of.
    def each_group : Nil
      @groups.each do |id|
        if group = DppmRestApi.config.file.groups.find { |group| group.id === id }
          yield group
        else
          DppmRestApi.config.logger.warn "user #{name} is a member of an invalid group ##{id}"
        end
      end
    end

    # yields each Group that the user is a member of to the block, and returns
    # an Iterator of the results of the block. Important: if the result of the
    # block is nil, it will be ignored (i.e. not a member of the resulting
    # array) -- hence the resulting array can be of a different size than the
    # number of groups of which this user is a member.
    def map_groups(&block : Group -> R) forall R
      idx = -1
      # ^^ so that when we add one it is the zero index (since crystal doesn't
      # have an equivalend of the prefix '--' operator)
      Iterator.of do
        each_group { |group| yield group }
        Iterator.stop
      end.reject &.nil?
    end

    # Yield each group to a block and return the first group for which the block
    # returns a truthy value
    def find_group?
      each_group { |group| return group if yield group }
    end
  end
end
