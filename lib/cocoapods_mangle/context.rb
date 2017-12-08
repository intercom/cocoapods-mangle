module CocoapodsMangle
  # Context for mangling
  class Context
    # @!attribute xcconfig_path
    #   @return [String] The path to the mangle xcconfig
    attr_accessor :xcconfig_path
    # @!attribute mangle_prefix
    #   @return [String] The mangle prefix to be used
    attr_accessor :mangle_prefix
    # @!attribute pods_project
    #   @return [Pod::Project] The Pods Xcode project
    attr_accessor :pods_project
    # @!attribute umbrella_pod_targets
    #   @return [Array<Pod::Installer::PostInstallHooksContext::UmbrellaTargetDescription>]
    #           The umbrella targets to be mangled
    attr_accessor :umbrella_pod_targets

    # Initializes the context for mangling
    # @param  [Pod::Installer::PostInstallHooksContext] installer_context
    #         The post install context
    # @param  [Hash] options
    # @option options [String] :xcconfig_path
    #                 The path to the mangling xcconfig
    # @option options [String] :mangle_prefix
    #                 The prefix to prepend to mangled symbols
    # @option options [Array<String>] :targets
    #                 The user targets whose dependencies should be mangled
    def initialize(installer_context, options)
      @xcconfig_path = build_xcconfig_path(installer_context, options[:xcconfig_path])
      @pods_project = installer_context.pods_project
      @umbrella_pod_targets = build_umbrella_pod_targets(installer_context, options[:targets])
      @mangle_prefix = build_mangle_prefix(@umbrella_pod_targets, options[:mangle_prefix])
    end

    # @return [String] A checksum representing the current state of the target dependencies
    def specs_checksum
      gem_summary = "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}"
      specs = @umbrella_pod_targets.map(&:specs).flatten.uniq
      specs_summary = specs.map(&:checksum).join(',')
      Digest::SHA1.hexdigest("#{gem_summary},#{specs_summary}")
    end

    private

    def build_xcconfig_path(installer_context, user_xcconfig_path)
      unless user_xcconfig_path
        xcconfig_dir = installer_context.sandbox.target_support_files_root
        xcconfig_filename = "#{CocoapodsMangle::NAME}.xcconfig"
        return File.join(xcconfig_dir, xcconfig_filename)
      end
      File.join(installer_context.sandbox.root.parent, user_xcconfig_path)
    end

    def build_umbrella_pod_targets(installer_context, user_targets)
      if user_targets.nil? || user_targets.empty?
        return installer_context.umbrella_targets
      end
      installer_context.umbrella_targets.reject do |target|
        target_names = target.user_targets.map(&:name)
        (user_targets & target_names).empty?
      end
    end

    def build_mangle_prefix(umbrella_pod_targets, user_mangle_prefix)
      unless user_mangle_prefix
        project_path = umbrella_pod_targets.first.user_project.path
        return File.basename(project_path, '.xcodeproj') + '_'
      end
      user_mangle_prefix
    end
  end
end
