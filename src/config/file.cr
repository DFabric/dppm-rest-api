require "./users"

module DppmRestApi
  class Config
    struct File
      include JSON::Serializable
      property roles : Hash(String, Role)
      property users : Array(User)
    end
  end
end
