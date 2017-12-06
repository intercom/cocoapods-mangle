require 'cocoapods_mangle/post_install'

module CocoapodsMangle
  # Registers for CocoaPods plugin hooks
  module Hooks
    Pod::HooksManager.register(CocoapodsMangle::NAME, :post_install) do |installer_context, options|
      xcconfig_path = CocoapodsMangle::Hooks.xcconfig_path(installer_context, options[:xcconfig_path])
      umbrella_pod_targets = CocoapodsMangle::Hooks.umbrella_pod_targets(installer_context, options[:targets])
      mangle_prefix = CocoapodsMangle::Hooks.mangle_prefix(umbrella_pod_targets, options[:mangle_prefix])
      post_install = CocoapodsMangle::PostInstall.new(xcconfig_path: xcconfig_path,
                                                      umbrella_pod_targets: umbrella_pod_targets,
                                                      pods_project: installer_context.pods_project,
                                                      mangle_prefix: mangle_prefix)
      Pod::UI.titled_section 'Updating mangling' do
        post_install.run!
      end
    end

    # Gets the mangle xcconfig path to use
    # @param  [Pod::Installer::PostInstallHooksContext] installer_context
    #         The post install context
    # @param  [String] xcconfig_path
    #         The mangle xcconfig path provided by the user
    # @return The mangle xcconfig path to be used
    def self.xcconfig_path(installer_context, user_xcconfig_path)
      unless user_xcconfig_path
        xcconfig_dir = installer_context.sandbox.target_support_files_root
        xcconfig_filename = "#{CocoapodsMangle::NAME}.xcconfig"
        return File.join(xcconfig_dir, xcconfig_filename)
      end
      File.join(installer_context.sandbox.root.parent, user_xcconfig_path)
    end

    # Gets the umbrella pod targets to mangle
    # @param  [Pod::Installer::PostInstallHooksContext] installer_context
    #         The post install context
    # @param  [Array<String>] user_targets
    #         The names of the user targets that should be mangled
    # @return [Array<Pod::Installer::PostInstallHooksContext::UmbrellaTargetDescription>]
    #         The pod umbrella targets to be mangled
    def self.umbrella_pod_targets(installer_context, user_targets)
      if user_targets.nil? || user_targets.empty?
        return installer_context.umbrella_targets
      end
      installer_context.umbrella_targets.reject do |target|
        target_names = target.user_targets.map(&:name)
        (user_targets & target_names).empty?
      end
    end

    # Gets the mangle prefix to be used
    # @param  [Array<Pod::Installer::PostInstallHooksContext::UmbrellaTargetDescription>] umbrella_pod_targets
    #         The umbrella pod targets that will be mangled
    # @param  [String] user_mangle_prefix
    #         The mangle prefix provided by the user
    # @return The mangle prefix provided by the user
    def self.mangle_prefix(umbrella_pod_targets, user_mangle_prefix)
      unless user_mangle_prefix
        project_path = umbrella_pod_targets.first.user_project.path
        return File.basename(project_path, '.xcodeproj') + '_'
      end
      user_mangle_prefix
    end
  end
end
