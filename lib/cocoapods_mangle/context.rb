module CocoapodsMangle
  # Context for mangling
  class Context
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
      @installer_context = installer_context
      @options = options
    end

    # @return [String] The path to the mangle xcconfig
    def xcconfig_path
      return default_xcconfig_path unless @options[:xcconfig_path]
      File.join(@installer_context.sandbox.root.parent, @options[:xcconfig_path])
    end

    # @return [String] The mangle prefix to be used
    def mangle_prefix
      return default_mangle_prefix unless @options[:mangle_prefix]
      @options[:mangle_prefix]
    end

    # @return [String] The path to pods project
    def pods_project_path
      @installer_context.pods_project.path
    end

    # @return [Array<String>] The targets in the pods project to be mangled
    def pod_target_labels
      umbrella_pod_targets.map(&:cocoapods_target_label)
    end

    # @return [Array<String>] Paths to all pod xcconfig files which should be updated
    def pod_xcconfig_paths
      pod_xcconfigs = []
      @installer_context.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          pod_xcconfigs << config.base_configuration_reference.real_path
        end
      end
      pod_xcconfigs.uniq
    end

    # @return [String] A checksum representing the current state of the target dependencies
    def specs_checksum
      gem_summary = "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}"
      specs = umbrella_pod_targets.map(&:specs).flatten.uniq
      specs_summary = specs.map(&:checksum).join(',')
      Digest::SHA1.hexdigest("#{gem_summary},#{specs_summary}")
    end

    private

    def umbrella_pod_targets
      if @options[:targets].nil? || @options[:targets].empty?
        return @installer_context.umbrella_targets
      end
      @installer_context.umbrella_targets.reject do |target|
        target_names = target.user_targets.map(&:name)
        (@options[:targets] & target_names).empty?
      end
    end

    def default_xcconfig_path
      xcconfig_dir = @installer_context.sandbox.target_support_files_root
      xcconfig_filename = "#{CocoapodsMangle::NAME}.xcconfig"
      File.join(xcconfig_dir, xcconfig_filename)
    end

    def default_mangle_prefix
      project_path = umbrella_pod_targets.first.user_project.path
      project_name = File.basename(project_path, '.xcodeproj')
      project_name.tr(' ', '_') + '_'
    end
  end
end
