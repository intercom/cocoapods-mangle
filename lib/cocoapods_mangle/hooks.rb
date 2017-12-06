require 'cocoapods_mangle/post_install'

module CocoapodsMangle
  module Hooks
    Pod::HooksManager.register(CocoapodsMangle::NAME, :post_install) do |installer_context, options|
      xcconfig_path = CocoapodsMangle::Hooks.xcconfig_path(installer_context, options)
      pod_targets = CocoapodsMangle::Hooks.pod_targets(installer_context, options)
      mangle_prefix = CocoapodsMangle::Hooks.mangle_prefix(pod_targets, options)
      post_install = CocoapodsMangle::PostInstall.new(xcconfig_path: xcconfig_path,
                                                      pod_targets: pod_targets,
                                                      pods_project: installer_context.pods_project,
                                                      mangle_prefix: mangle_prefix)
      Pod::UI.titled_section 'Updating mangling' do
        post_install.run!
      end
    end

    def self.xcconfig_path(installer_context, options)
      unless options[:xcconfig_path]
        xcconfig_dir = installer_context.sandbox.target_support_files_root
        xcconfig_filename = "#{CocoapodsMangle::NAME}.xcconfig"
        return File.join(xcconfig_dir, xcconfig_filename)
      end
      File.join(installer_context.sandbox.root.parent, options[:xcconfig_path])
    end

    def self.pod_targets(installer_context, options)
      if options[:targets].nil? || options[:targets].empty?
        return installer_context.umbrella_targets
      end
      pods_target_labels = options[:targets].map { |t| "Pods-#{t}" }
      installer_context.umbrella_targets.select do |target|
        pods_target_labels.include? target.cocoapods_target_label
      end
    end

    def self.mangle_prefix(pod_targets, options)
      unless options[:mangle_prefix]
        project_path = pod_targets.first.user_project.path
        return File.basename(project_path, '.xcodeproj') + '_'
      end
      options[:mangle_prefix]
    end
  end
end
