require "./user"

module DppmRestApi
  struct Config
    struct File
      include JSON::Serializable
      property groups : Array(Group)
      property users : Array(User)

      def user(named username) : User?
        users.find { |user| user.name == username }
      end
    end
  end
end
