require 'digest'
require 'cocoapods'
require 'cocoapods_mangle/config'

module CocoapodsMangle
  # Runs the post mangling post install action
  class PostInstall
    # @param [Hash] params the params for mangling.
    # @option params [String] :xcconfig_path 
    #                The path to the mangling xcconfig
    # @option params [String] :mangle_prefix
    #                The prefix to prepend to mangled symbols
    # @option params [Pod::Project] :pods_project
    #                The Pods Xcode project
    # @option params [Array<Pod::Installer::PostInstallHooksContext::UmbrellaTargetDescription>] :umbrella_pod_targets
    #                the umbrella pod targets whose dependencies should be mangled
    def initialize(params)
      @xcconfig_path = params[:xcconfig_path]
      @mangle_prefix = params[:mangle_prefix]
      @pods_project = params[:pods_project]
      @umbrella_pod_targets = params[:umbrella_pod_targets]
    end

    # Run the post install action
    def run!
      config.update_mangling! if config.needs_update?
      config.update_pod_xcconfigs_for_mangling!
    end

    # @return [CocoapodsMangle::Config] The mangling config object
    def config
      @config ||= CocoapodsMangle::Config.new(xcconfig_path: @xcconfig_path,
                                              mangle_prefix: @mangle_prefix,
                                              pods_project: @pods_project,
                                              umbrella_pod_targets: @umbrella_pod_targets,
                                              specs_checksum: specs_checksum)
    end

    # @return [String] A checksum representing the current state of the target dependencies
    def specs_checksum
      gem_summary = "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}"
      specs = @umbrella_pod_targets.map(&:specs).flatten.uniq
      specs_summary = specs.map(&:checksum).join(',')
      Digest::SHA1.hexdigest("#{gem_summary},#{specs_summary}")
    end
  end
end
