require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/context'

RSpec.shared_examples 'initializing context' do
  it 'sets the correct values' do
    context = CocoapodsMangle::Context.new(installer_context, options)
    expect(context.xcconfig_path).to eq(xcconfig_path)
    expect(context.umbrella_pod_targets).to eq(umbrella_pod_targets)
    expect(context.pods_project).to eq(pods_project)
    expect(context.mangle_prefix).to eq(mangle_prefix)
  end
end

describe CocoapodsMangle::Context do
  let(:umbrella_targets) do
    [
      instance_double('umbrella target A', cocoapods_target_label: 'Pods-A', user_targets: [instance_double('target A', name: 'A')]),
      instance_double('umbrella target B', cocoapods_target_label: 'Pods-B', user_targets: [instance_double('target B', name: 'B')]),
      instance_double('umbrella target C', cocoapods_target_label: 'Pods-C', user_targets: [instance_double('target C', name: 'C')])
    ]
  end
  let(:installer_context) { instance_double('installer', pods_project: double('pods project'), umbrella_targets: umbrella_targets) }

  before do
    allow(installer_context).to receive_message_chain(:sandbox, :root, :parent).and_return( Pathname.new('/parent') )
    allow(installer_context).to receive_message_chain(:sandbox, :target_support_files_root).and_return( Pathname.new('/support_files') )
    allow(umbrella_targets.first).to receive_message_chain(:user_project, :path).and_return('path/to/Project.xcodeproj')
  end

  context 'Initialization' do
    context 'all user defined options' do
      let(:options) { { targets: ['A', 'B'], xcconfig_path: 'path/to/mangle.xcconfig', mangle_prefix: 'prefix_' } }
      let(:xcconfig_path) { "/parent/#{options[:xcconfig_path]}" }
      let(:umbrella_pod_targets) { umbrella_targets[0..1] }
      let(:pods_project) { installer_context.pods_project }
      let(:mangle_prefix) { options[:mangle_prefix] }

      include_examples 'initializing context'
    end

    context 'only targets defined in options' do
      let(:options) { { targets: ['A', 'B'] } }
      let(:xcconfig_path) { "/support_files/#{CocoapodsMangle::NAME}.xcconfig" }
      let(:umbrella_pod_targets) { umbrella_targets[0..1] }
      let(:pods_project) { installer_context.pods_project }
      let(:mangle_prefix) { 'Project_' }

      include_examples 'initializing context'
    end

    context 'no options' do
      let(:options) { {} }
      let(:xcconfig_path) { "/support_files/#{CocoapodsMangle::NAME}.xcconfig" }
      let(:umbrella_pod_targets) { umbrella_targets[0..2] }
      let(:pods_project) { installer_context.pods_project }
      let(:mangle_prefix) { 'Project_' }

      include_examples 'initializing context'
    end
  end

  context '.specs_checksum' do
    let(:gem_summary) { "#{CocoapodsMangle::NAME}=#{CocoapodsMangle::VERSION}" }
    let(:spec_A) { instance_double('Spec A', checksum: 'checksum_A') }
    let(:spec_B) { instance_double('Spec B', checksum: 'checksum_B') }
    let(:subject) { CocoapodsMangle::Context.new(installer_context, targets: ['A']) }

    before do
      allow(umbrella_targets.first).to receive(:specs).and_return([spec_A, spec_B])
    end

    it 'gives the checksum' do
      summary = "#{gem_summary},checksum_A,checksum_B"
      expect(subject.specs_checksum).to eq(Digest::SHA1.hexdigest(summary))
    end
  end
end
