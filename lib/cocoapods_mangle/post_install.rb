require 'digest'
require 'cocoapods'
require 'cocoapods_mangle/config'

module CocoapodsMangle
  class PostInstall
    def initialize(params)
      @xcconfig_path = params[:xcconfig_path]
      @pods_project = params[:pods_project]
      @pod_targets = params[:pod_targets]
      @mangle_prefix = params[:mangle_prefix]
    end

    def run!
      config.update_mangling! if config.needs_update?
      config.update_pod_xcconfigs_for_mangling!
    end

    def config
      @config ||= CocoapodsMangle::Config.new(xcconfig_path: @xcconfig_path,
                                              mangle_prefix: @mangle_prefix,
                                              pods_project: @pods_project,
                                              pod_targets: @pod_targets,
                                              specs_checksum: specs_checksum)
    end

    def specs_checksum
      gem_summary = "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}"
      specs = @pod_targets.map(&:specs).flatten.uniq
      specs_summary = specs.map(&:checksum).join(',')
      Digest::SHA1.hexdigest("#{gem_summary},#{specs_summary}")
    end
  end
end
