module CocoapodsMangle
  class Builder
    BUILT_PRODUCTS_DIR = 'build/Release-iphonesimulator'

    def initialize(pods_project, pod_targets)
      @pods_project = pods_project
      @pod_targets = pod_targets
    end

    def build!
      FileUtils.remove_dir(BUILT_PRODUCTS_DIR, true)
      @pod_targets.each { |target| build_target(target.cocoapods_target_label) }
    end

    def binaries_to_mangle
      static_binaries_to_mangle + dynamic_binaries_to_mangle
    end

    private

    def build_target(target)
      output = `xcodebuild -project "#{@pods_project.path}" -target "#{target}" -configuration Release -sdk iphonesimulator build 2>&1`
      return true if $?.success?
      raise "error: Building the Pods target '#{target}' failed.\ This is the build log:\n#{output}"
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
