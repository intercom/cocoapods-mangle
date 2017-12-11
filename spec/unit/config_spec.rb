require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/config'

describe CocoapodsMangle::Config do
  let(:context) do
    instance_double('Mangle context',
                    xcconfig_path: 'path/to/mangle.xcconfig',
                    pod_target_labels: ['Pods-A'],
                    pods_project_path: 'path/to/Pods.xcodeproj',
                    mangle_prefix: 'prefix_',
                    specs_checksum: 'checksum',
                    pod_xcconfig_paths: ['path/to/A.xcconfig', 'path/to/B.xcconfig'])
  end
  let(:subject) do
    CocoapodsMangle::Config.new(context)
  end

  context '.update_mangling!' do
    let(:xcconfig_file) { double('config') }
    let(:binaries_to_mangle) { ['binary_A', 'binary_B'] }
    let(:mangling_defines) { ['A=B', 'C=D'] }
    let(:builder) { double('builder') }

    before do
      allow(CocoapodsMangle::Builder).to receive(:new).with(context.pods_project_path, context.pod_target_labels).and_return(builder)
      allow(builder).to receive(:build!)
      allow(builder).to receive(:binaries_to_mangle).and_return(binaries_to_mangle)
      allow(CocoapodsMangle::Defines).to receive(:mangling_defines).with(context.mangle_prefix, binaries_to_mangle).and_return(mangling_defines)
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(context.xcconfig_path, 'w').and_yield(xcconfig_file)
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
    let(:xcconfig_file) { double('config file') }
    let(:xcodeproj_config) { double('xcodeproj config') }
    let(:xcconfig_specs_checksum) { 'checksum' }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(context.xcconfig_path).and_return(true)
      allow(File).to receive(:new).and_call_original
      allow(File).to receive(:new).with(context.xcconfig_path).and_return(xcconfig_file)
      allow(Xcodeproj::Config).to receive(:new).with(xcconfig_file).and_return(xcodeproj_config)
      allow(xcodeproj_config).to receive(:to_hash).and_return('MANGLING_DEFINES' => 'A=B C=D',
                                                              'MANGLED_SPECS_CHECKSUM' => "#{xcconfig_specs_checksum}")
    end

    context 'equal checksums' do
      before do
        allow(context).to receive(:specs_checksum).and_return('checksum')
      end

      it 'does not need an update' do
        expect(subject.needs_update?).to eq(false)
      end
    end

    context 'different checksums' do
      before do
        allow(context).to receive(:specs_checksum).and_return('other_checksum')
      end

      it 'needs an update' do
        expect(subject.needs_update?).to eq(true)
      end
    end

    context 'no config' do
      before do
        allow(File).to receive(:exist?).with(context.xcconfig_path).and_return(false)
      end

      it 'needs an update' do
        expect(subject.needs_update?).to eq(true)
      end
    end
  end

  context '.update_pod_xcconfigs_for_mangling!' do
    it 'updates each unique config' do
      context.pod_xcconfig_paths.each do |pod_xcconfig|
        expect(subject).to receive(:update_pod_xcconfig_for_mangling!).with(pod_xcconfig)
      end
      subject.update_pod_xcconfigs_for_mangling!
    end
  end

  context '.update_pod_xcconfig_for_mangling!' do
    let(:pod_xcconfig_path) { '/path/to/pod.xcconfig' }
    let(:pod_xcconfig_content) { "GCC_PREPROCESSOR_DEFINITIONS = A=B\nKEY = VALUE" }
    let(:pod_xcconfig_file) { double('pod_config') }

    before do
      allow(File).to receive(:readlines).and_call_original
      allow(File).to receive(:readlines).and_return(pod_xcconfig_content.split("\n"))
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).and_return(pod_xcconfig_content)
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(pod_xcconfig_path, 'w').and_yield(pod_xcconfig_file)
    end

    it 'updates the pod config' do
      pod_xcconfig_contents = ''
      expect(pod_xcconfig_file).to receive(:write) { |arg| pod_xcconfig_contents = arg }
      subject.update_pod_xcconfig_for_mangling!(pod_xcconfig_path)
      expect(pod_xcconfig_contents).to eq("#include \"#{context.xcconfig_path}\"\nGCC_PREPROCESSOR_DEFINITIONS = A=B $(MANGLING_DEFINES)\nKEY = VALUE")
    end
  end
end
