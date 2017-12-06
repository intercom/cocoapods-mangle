require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/post_install'

describe CocoapodsMangle::PostInstall do
  let(:xcconfig_path) { 'path/to/mangle.xcconfig' }
  let(:pod_targets) { [instance_double('target', cocoapods_target_label: 'Pods-A')] }
  let(:pods_project) { double('pods project') }
  let(:mangle_prefix) { 'prefix_' }
  let(:subject) do
    CocoapodsMangle::PostInstall.new(xcconfig_path: xcconfig_path,
                                     pod_targets: pod_targets,
                                     pods_project: pods_project,
                                     mangle_prefix: mangle_prefix)
  end

  context '.run!' do
    let(:config) { double('config') }
    let(:specs_checksum) { 'checksum' }

    before do
      allow(subject).to receive(:config).and_return(config)
      allow(subject).to receive(:specs_checksum).and_return(specs_checksum)
    end

    it 'updates mangling and pod xcconfigs' do
      allow(config).to receive(:needs_update?).and_return(true)
      expect(config).to receive(:update_mangling!)
      expect(config).to receive(:update_pod_xcconfigs_for_mangling!)

      subject.run!
    end

    it 'updates pod xcconfigs only' do
      allow(config).to receive(:needs_update?).and_return(false)
      expect(config).not_to receive(:update_mangling!)
      expect(config).to receive(:update_pod_xcconfigs_for_mangling!)

      subject.run!
    end
  end

  context '.config' do
    let(:specs_checksum) { 'checksum' }

    before do
      allow(subject).to receive(:specs_checksum).and_return(specs_checksum)
    end

    it 'creates a config' do
      expect(CocoapodsMangle::Config).to receive(:new).with(xcconfig_path: xcconfig_path,
                                                            mangle_prefix: mangle_prefix,
                                                            pods_project: pods_project,
                                                            pod_targets: pod_targets,
                                                            specs_checksum: specs_checksum).and_call_original
      expect(subject.config).to be_a CocoapodsMangle::Config
    end
  end

  context '.specs_checksum' do
    let(:gem_summary) { "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}" }
    let(:spec_A) { instance_double('Spec A', checksum: 'checksum_A') }
    let(:spec_B) { instance_double('Spec B', checksum: 'checksum_B') }

    before do
      allow(pod_targets.first).to receive(:specs).and_return([spec_A, spec_B])
    end

    it 'gives the checksum' do
      summary = "#{gem_summary},checksum_A,checksum_B"
      expect(subject.specs_checksum).to eq(Digest::SHA1.hexdigest(summary))
    end
  end
end
