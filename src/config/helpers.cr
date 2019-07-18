require "./errors"

# A series of utility functions for selecting and modifying users and groups
module DppmRestApi
  struct Config
    module Helpers
      # A helper method for the select_users method -- splits a comma-separated
      # list of numbers in a string into a `Set` of `Int32` values.
      def split_numbers(number_list : String) : Set(Int32)
        numbers = Set(Int32).new
        split_numbers number_list do |number|
          numbers.add number
        end
        numbers
      end

      def split_numbers(number_list)
        number_list.split ',', remove_empty: true do |raw_group_id|
          yield raw_group_id.to_i? || raise InvalidGroupID.new raw_group_id
        end
      end

      # select the users from the current configuration according to the name,
      # groups the user is a member of, and/or the user's API key.
      def selected_users(match_name, match_groups, api_key, from users_list)
        # Filter by name
        if name = match_name
          if stripped_name = name.lchop?('/').try(&.rchop?('/'))
            # match by regex
            name_regex = Regex.new stripped_name
            users_list = users_list.select do |user|
              name_regex =~ user.name
            end
          else
            # find users by exact match
            users_list = users_list.select do |user|
              user.name == name
            end
          end
        end
        # Filter by group membership
        if groups = match_groups
          group_matches = Set(Set(Int32)).new
          groups.split ':', remove_empty: true do |part|
            group_matches << split_numbers part
          end
          users_list = users_list.select do |user|
            group_matches.any? do |group_set|
              group_set.all? do |group|
                user.group_ids.includes? group
              end
            end
          end
        end
        # filter by API key if specified.
        if key = api_key
          users_list = users_list.select { |user| user.api_key_hash.verify key }
          # freak out if multiple users were found.
          raise DuplicateAPIKey.new users_list if users_list.size > 1
        end
        users_list
      end

      # :ditto:
      #
      # Yield each of the matching users to a block.
      def selected_users(match_name,
                         match_groups,
                         api_key,
                         from users_list,
                         &block : DppmRestApi::Config::User -> DppmRestApi::Config::User?)
        selected_users(match_name, match_groups, api_key, from: users_list).each do |user|
          old_user = user
          users_list.delete user
          users_list << ((yield user) || old_user)
        end
      end
    end
  end
end
