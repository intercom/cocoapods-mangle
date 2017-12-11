require 'xcodeproj'
require 'cocoapods'
require 'cocoapods_mangle/builder'
require 'cocoapods_mangle/defines'

module CocoapodsMangle
  # Manages xcconfig files for configuring mangling.
  class Config
    MANGLING_DEFINES_XCCONFIG_KEY = 'MANGLING_DEFINES'
    MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY = 'MANGLED_SPECS_CHECKSUM'

    # @param [CocoapodsMangle::Context] context The context for mangling.
    def initialize(context)
      @context = context
    end

    # Update the mangling xcconfig file with new mangling defines
    def update_mangling!
      Pod::UI.message '- Updating mangling xcconfig' do
        builder = Builder.new(@context.pods_project_path, @context.pod_target_labels)
        builder.build!

        defines = Defines.mangling_defines(@context.mangle_prefix, builder.binaries_to_mangle)

        contents = <<~MANGLE_XCCONFIG
          // This config file is automatically generated any time Podfile.lock changes
          // Changes should be committed to git along with Podfile.lock

          #{MANGLING_DEFINES_XCCONFIG_KEY} = #{defines.join(' ')}

          // This checksum is used to ensure mangling is up to date
          #{MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY} = #{@context.specs_checksum}
        MANGLE_XCCONFIG

        Pod::UI.message "- Writing '#{File.basename(@context.xcconfig_path)}'"
        File.open(@context.xcconfig_path, 'w') { |xcconfig| xcconfig.write(contents) }
      end
    end

    # Does the mangling xcconfig need to be updated?
    # @return  [Truthy] Does the xcconfig need to be updated?
    def needs_update?
      return true unless File.exist?(@context.xcconfig_path)
      xcconfig_hash = Xcodeproj::Config.new(File.new(@context.xcconfig_path)).to_hash
      needs_update = xcconfig_hash[MANGLED_SPECS_CHECKSUM_XCCONFIG_KEY] != @context.specs_checksum
      Pod::UI.message '- Mangling config already up to date' unless needs_update
      needs_update
    end

    # Update all pod xcconfigs to use the mangling defines
    def update_pod_xcconfigs_for_mangling!
      Pod::UI.message '- Updating Pod xcconfig files' do
        @context.pod_xcconfig_paths.each do |pod_xcconfig_path|
          Pod::UI.message "- Updating '#{File.basename(pod_xcconfig_path)}'"
          update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
        end
      end
    end

    # Update a mangling config to use the mangling defines
    # @param    [String] pod_xcconfig_path
    #           Path to the pod xcconfig to update
    def update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
      mangle_xcconfig_include = "#include \"#{@context.xcconfig_path}\"\n"

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
