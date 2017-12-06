require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/config'

describe CocoapodsMangle::Config do
  let(:xcconfig_path) { 'path/to/mangle.xcconfig' }
  let(:umbrella_pod_targets) { [instance_double('target', cocoapods_target_label: 'Pods-A')] }
  let(:pods_project) { double('pods project') }
  let(:mangle_prefix) { 'prefix_' }
  let(:specs_checksum) { 'checksum' }
  let(:subject) do
    CocoapodsMangle::Config.new(xcconfig_path: xcconfig_path,
                                umbrella_pod_targets: umbrella_pod_targets,
                                pods_project: pods_project,
                                mangle_prefix: mangle_prefix,
                                specs_checksum: specs_checksum)
  end

  context '.update_mangling!' do
    let(:xcconfig_file) { double('config') }
    let(:mangle_prefix) { 'prefix_' }
    let(:binaries_to_mangle) { ['binary_A', 'binary_B'] }
    let(:mangling_defines) { ['A=B', 'C=D'] }
    let(:builder) { double('builder') }

    before do
      allow(CocoapodsMangle::Builder).to receive(:new).with(pods_project, umbrella_pod_targets).and_return(builder)
      allow(builder).to receive(:build!)
      allow(builder).to receive(:binaries_to_mangle).and_return(binaries_to_mangle)
      allow(CocoapodsMangle::Defines).to receive(:mangling_defines).with(mangle_prefix, binaries_to_mangle).and_return(mangling_defines)
      allow(File).to receive(:open).with(xcconfig_path, 'w').and_yield(xcconfig_file)
    end

    it 'updates mangling' do
      expect(builder).to receive(:build!)
      xcconfig_contents = ''
      expect(xcconfig_file).to receive(:write) { |arg| xcconfig_contents = arg }

      subject.update_mangling!

      expect(xcconfig_contents).to include("MANGLING_DEFINES = #{mangling_defines.join(" ")}")
      expect(xcconfig_contents).to include('MANGLED_SPECS_CHECKSUM = checksum')
    end
  end

  context '.needs_update?' do
    let(:xcconfig_path) { "#{File.dirname(__FILE__)}/../fixtures/mangle.xcconfig" }

    context 'equal checksums' do
      let(:specs_checksum) { 'checksum' }

      it 'does not need an update' do
        expect(subject.needs_update?).to eq(false)
      end
    end

    context 'different checksums' do
      let(:specs_checksum) { 'other_checksum' }

      it 'needs an update' do
        expect(subject.needs_update?).to eq(true)
      end
    end

    context 'no config' do
      before do
        allow(File).to receive(:exist?).and_return(false)
      end

      it 'needs an update' do
        expect(subject.needs_update?).to eq(true)
      end
    end
  end

  context '.update_pod_xcconfigs_for_mangling!' do
    let(:pod_target) { double('target') }
    let(:debug_build_configuration) { double('debug') }
    let(:release_build_configuration) { double('release') }

    before do
      allow(pods_project).to receive(:targets).and_return([pod_target])
      build_configurations = [debug_build_configuration, release_build_configuration]
      allow(pod_target).to receive(:build_configurations).and_return(build_configurations)
      build_configurations.each do |config|
        allow(config).to receive_message_chain(:base_configuration_reference, :real_path).and_return('pod.xcconfig')
      end
    end

    it 'updates each unique config' do
      expect(subject).to receive(:update_pod_xcconfig_for_mangling!).with('pod.xcconfig').once
      subject.update_pod_xcconfigs_for_mangling!
    end
  end

  context '.update_pod_xcconfig_for_mangling!' do
    let(:pod_xcconfig_path) { '/path/to/pod.xcconfig' }
    let(:pod_xcconfig_content) { "GCC_PREPROCESSOR_DEFINITIONS = A=B\nKEY = VALUE" }
    let(:pod_xcconfig_file) { double('pod_config') }

    before do
      allow(File).to receive(:readlines).and_return(pod_xcconfig_content.split("\n"))
      allow(File).to receive(:read).and_return(pod_xcconfig_content)
      allow(File).to receive(:open).with(pod_xcconfig_path, 'w').and_yield(pod_xcconfig_file)
    end

    it 'updates the pod config' do
      pod_xcconfig_contents = ''
      expect(pod_xcconfig_file).to receive(:write) { |arg| pod_xcconfig_contents = arg }
      subject.update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
      expect(pod_xcconfig_contents).to eq("#include \"#{xcconfig_path}\"\nGCC_PREPROCESSOR_DEFINITIONS = A=B $(MANGLING_DEFINES)\nKEY = VALUE")
    end
  end
end