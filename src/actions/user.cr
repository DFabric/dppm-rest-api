module DppmRestApi::Actions::User
  struct AddUserBody
    include JSON::Serializable
    getter name : String
    getter groups : Array(Int32)
  end

  relative_post nil do |context|
    if Actions.has_access? context, Access::Create
      userdata = AddUserBody.from_json context.request.body_io
      # TODO add user
      next context
    end
    raise Unauthorized.new context
  end
  relative_delete nil do |context|
    if Actions.has_access? context, Access::Delete
      userdata = AddUserBody.from_json context.request.body_io
      # TODO delete a user
      next context
    end
    raise Unauthorized.new context
  end
  relative_get nil do |context|
    if Actions.has_access? context, Access::Read
      userdata = AddUserBody.from_json context.request.body_io
      # TODO delete a user
      next context
    end
    raise Unauthorized.new context
  end
end
