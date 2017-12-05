require 'xcodeproj'
require 'cocoapods_mangle/builder'
require 'cocoapods_mangle/defines'

module CocoapodsMangle
  class Config
    MANGLING_DEFINES_XCCONFIG_KEY = 'MANGLING_DEFINES'
    MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY = 'MANGLED_SPECS_CHECKSUM'

    def initialize(params)
      @xcconfig_path = params[:xcconfig_path]
      @prefix = params[:mangle_prefix]
      @pods_project = params[:pods_project]
      @pod_targets = params[:pod_targets]
      @specs_checksum = params[:specs_checksum]
    end

    def update_mangling!
      builder = Builder.new(@pods_project, @pod_targets)
      builder.build!

      defines = Defines.mangling_defines(@prefix, builder.binaries_to_mangle)

      contents = <<~MANGLE_XCCONFIG
        // This config file is automatically generated any time Podfile.lock changes
        // Changes should be committed to git along with Podfile.lock

        #{MANGLING_DEFINES_XCCONFIG_KEY} = #{defines.join(' ')}

        // This checksum is used to ensure mangling is up to date
        #{MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY} = #{@specs_checksum}
      MANGLE_XCCONFIG

      File.open(@xcconfig_path, 'w') { |xcconfig| xcconfig.write(contents) }
    end

    def needs_update?
      return true unless File.exist?(@xcconfig_path)
      xcconfig_hash = Xcodeproj::Config.new(File.new(@xcconfig_path)).to_hash
      xcconfig_hash[MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY] != @specs_checksum
    end

    def update_pod_xcconfigs_for_mangling!
      pod_xcconfigs = Set.new

      @pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          pod_xcconfigs.add(config.base_configuration_reference.real_path)
        end
      end

      pod_xcconfigs.each do |pod_xcconfig_path|
        update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
      end
    end

    def update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
      mangle_xcconfig_include = "#include \"#{@xcconfig_path}\"\n"

      gcc_preprocessor_defs = File.readlines(pod_xcconfig_path).select { |line| line =~ /GCC_PREPROCESSOR_DEFINITIONS/ }.first
      gcc_preprocessor_defs.strip!

      xcconfig_contents = File.read(pod_xcconfig_path)
      # import the mangling config
      new_xcconfig_contents = mangle_xcconfig_include + xcconfig_contents
      # update GCC_PREPROCESSOR_DEFINITIONS to include mangling
      new_xcconfig_contents.sub!(gcc_preprocessor_defs, gcc_preprocessor_defs + " $(#{MANGLING_DEFINES_XCCONFIG_KEY})")
      File.open(pod_xcconfig_path, 'w') { |pod_xcconfig| pod_xcconfig.write(new_xcconfig_contents) }
    end
  end
end
