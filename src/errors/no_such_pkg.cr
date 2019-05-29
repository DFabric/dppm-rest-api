module DppmRestApi
  class NoSuchPackage < NotFound
    setter cause

    def initialize(context, package_name : String)
      super context, "no such message found called \"" + package_name + '"'
    end
  end
end
