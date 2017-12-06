require 'cocoapods'

module CocoapodsMangle
  # Builds the supplied targets of a Pods Xcode project.
  #
  # This is useful for building pods for mangling purposes
  class Builder
    BUILT_PRODUCTS_DIR = 'build/Release-iphonesimulator'

    # @param    [Pod::Project] pods_project
    #           the pods project to build.
    #
    # @param    [Array<Pod::Installer::PostInstallHooksContext::UmbrellaTargetDescription>] umbrella_pod_targets
    #           the umbrella pod targets to build.
    def initialize(pods_project, umbrella_pod_targets)
      @pods_project = pods_project
      @umbrella_pod_targets = umbrella_pod_targets
    end

    # Build the pods project
    def build!
      FileUtils.remove_dir(BUILT_PRODUCTS_DIR, true)
      @umbrella_pod_targets.each { |target| build_target(target.cocoapods_target_label) }
    end

    # Gives the built binaries to be mangled
    # @return  [Array<String>] Paths to the build pods binaries
    def binaries_to_mangle
      static_binaries_to_mangle + dynamic_binaries_to_mangle
    end

    private

    def build_target(target)
      Pod::UI.message "- Building '#{target}'"
      output = `xcodebuild -project "#{@pods_project.path}" -target "#{target}" -configuration Release -sdk iphonesimulator build 2>&1`
      unless $?.success?
        raise "error: Building the Pods target '#{target}' failed.\ This is the build log:\n#{output}"
      end
    end

    def static_binaries_to_mangle
      Dir.glob("#{BUILT_PRODUCTS_DIR}/**/*.a").reject do |binary_path|
        File.basename(binary_path).start_with?('libPods-')
      end
    end

    def dynamic_binaries_to_mangle
      frameworks = Dir.glob("#{BUILT_PRODUCTS_DIR}/**/*.framework")
      framework = frameworks.reject do |framework_path|
        File.basename(framework_path).start_with?('Pods_')
      end
      framework.map { |path| "#{path}/#{File.basename(path, '.framework')}" }
    end
  end
end
