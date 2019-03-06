require "../../utils"
module DppmRestApi::Actions::Pkg
  ALL_PKGS = root_path
  ONE_PKG = "#{root_path}/:id"
  # List built packages
  get ALL_PKGS do |context|

  end
  # Clean unused built packages
  delete ALL_PKGS do |context|

  end
  # Query information about a given package
  get ONE_PKG do |context|

  end
  # Delete a given package
  delete ONE_PKG do |context|

  end
  module Build
    # Build a package, returning the ID of the built image, and perhaps a status
    # message? We could also use server-side events or a websocket to provide the
    # status of this action as it occurs over the API, rather than just returning
    # a result on completion.
    post "#{root_path}/:package" do |context|

    end
  end
end
