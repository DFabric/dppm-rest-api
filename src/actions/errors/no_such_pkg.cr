module DppmRestApi::Actions
  class NoSuchPackage < NotFound
    setter cause

    def initialize(context, package_name : String)
      super context, "no such package found called \"" + package_name + '"'
    end
  end
end
