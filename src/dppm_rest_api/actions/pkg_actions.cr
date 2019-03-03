require "../../utils"
module DppmRestApi::Actions::PkgActions
  # List built packages
  route :list do |context|

  end
  # Clean unused built packages
  route :clean do |context|

  end
  # Query information about a given package
  route :query do |context|

  end
  # Delete a given package
  route :delete do |context|

  end
  # Build a package, returning the ID of the built image, and perhaps a status
  # message? We could also use server-side events or a websocket to provide the
  # status of this action as it occurs over the API, rather than just returning
  # a result on completion.
  route :build do |context|

  end
end
