require 'digest'
require 'cocoapods'
require 'cocoapods_mangle/config'

module CocoapodsMangle
  # Runs the post mangling post install action
  class PostInstall
    # @param [CocoapodsMangle::Context] context The context for mangling.
    def initialize(context)
      @context = context
    end

    # Run the post install action
    def run!
      config.update_mangling! if config.needs_update?
      config.update_pod_xcconfigs_for_mangling!
    end

    # @return [CocoapodsMangle::Config] The mangling config object
    def config
      @config ||= CocoapodsMangle::Config.new(@context)
    end
  end
end
