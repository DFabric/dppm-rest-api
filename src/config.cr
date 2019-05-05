require "./user"

struct DppmRestApi::Config
  include JSON::Serializable
  property groups : Array(Group)
  property users : Array(User)

  def user(*, named username : String) : User?
    users.find { |user| user.name == username }
  end

  def user(*, authenticated_with api_key : String)
    users.find { |user| user.api_key_hash == api_key }
  end

  def group(*, named group_name : String) : Group?
    groups.find { |group| group.name == group_name }
  end
end
