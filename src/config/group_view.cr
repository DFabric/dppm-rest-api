# A `Group` view of an `User`, used to retrieve groups associated to an user.
struct DppmRestApi::Config::GroupView
  getter user : User
  getter groups : Array(Group)

  def initialize(@user : User, all_groups : Array(Group))
    @groups = all_groups.select { |group| @user.group_ids.includes? group.id }
  end

  # Yields each Group to the block for which the user is a member of.
  def each_group : Nil
    groups.each { |group| yield group }
  end

  # yields each Group that the user is a member of to the block, and returns
  # an Iterator of the results of the block. Important: if the result of the
  # block is nil, it will be ignored (i.e. not a member of the resulting
  # array) -- hence the resulting array can be of a different size than the
  # number of groups of which this user is a member.
  def map_groups(&block : Group -> R) forall R
    Iterator.of do
      each_group { |group| yield group }
      yield Iterator.stop
    end.reject &.nil?
  end

  # Yield each group to a block and return the first group for which the block
  # returns a truthy value
  def find_group?(&block)
    each_group { |group| return group if yield group }
  end
end
