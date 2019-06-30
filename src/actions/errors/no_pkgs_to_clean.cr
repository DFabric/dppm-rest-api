module DppmRestApi::Actions
  class NoPkgsToClean < NotFound
    setter cause

    def initialize(context)
      super context, "no packages to clean"
    end
  end
end
