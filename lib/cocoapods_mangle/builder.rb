require 'cocoapods'

module CocoapodsMangle
  # Builds the supplied targets of a Pods Xcode project.
  #
  # This is useful for building pods for mangling purposes
  class Builder
    BUILT_PRODUCTS_DIR = 'build/Release-iphonesimulator'

    # @param    [String] pods_project_path
    #           path to the pods project to build.
    #
    # @param    [Array<String>] pod_target_labels
    #           the pod targets to build.
    def initialize(pods_project_path, pod_target_labels)
      @pods_project_path = pods_project_path
      @pod_target_labels = pod_target_labels
    end

    # Build the pods project
    def build!
      FileUtils.remove_dir(BUILT_PRODUCTS_DIR, true)
      @pod_target_labels.each { |target| build_target(target) }
    end

    # Gives the built binaries to be mangled
    # @return  [Array<String>] Paths to the build pods binaries
    def binaries_to_mangle
      static_binaries_to_mangle + dynamic_binaries_to_mangle
    end

    private

    def build_target(target)
      Pod::UI.message "- Building '#{target}'"
      output = `xcodebuild -project "#{@pods_project_path}" -target "#{target}" -configuration Release -sdk iphonesimulator build 2>&1`
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
