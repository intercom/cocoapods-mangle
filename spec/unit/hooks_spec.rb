require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/hooks'

def trigger_post_install(installer_context, options)
  post_install_hooks = Pod::HooksManager.registrations[:post_install]
  hook = post_install_hooks.find { |h| h.plugin_name == CocoapodsMangle::NAME }
  hook.block.call(installer_context, options)
end

RSpec.shared_examples 'post install hook' do
  it 'passes the correct options' do
    expect(CocoapodsMangle::PostInstall).to receive(:new).with(post_install_options)
    expect(post_install).to receive(:run!)

    trigger_post_install(installer_context, options)
  end
end

describe CocoapodsMangle::Hooks do
  let(:umbrella_targets) do
    [
      instance_double('umbrella target A', cocoapods_target_label: 'Pods-A'),
      instance_double('umbrella target B', cocoapods_target_label: 'Pods-B'),
      instance_double('umbrella target C', cocoapods_target_label: 'Pods-C')
    ]
  end
  let(:installer_context) { instance_double('installer', pods_project: double('pods project'), umbrella_targets: umbrella_targets) }
  let(:post_install) { double('post install') }
  let(:options) { {} }
  let(:post_install_options) { {} }

  before do
    allow(installer_context).to receive_message_chain(:sandbox, :root, :parent).and_return( Pathname.new('/parent') )
    allow(installer_context).to receive_message_chain(:sandbox, :target_support_files_root).and_return( Pathname.new('/support_files') )
    allow(umbrella_targets.first).to receive_message_chain(:user_project, :path).and_return('path/to/Project.xcodeproj')
    allow(CocoapodsMangle::PostInstall).to receive(:new).with(post_install_options).and_return(post_install)
    allow(post_install).to receive(:run!)
  end

  context 'all user defined options' do
    let(:options) { { targets: ['A', 'B'], xcconfig_path: 'path/to/mangle.xcconfig', mangle_prefix: 'prefix_' } }
    let(:post_install_options) do
      {
        xcconfig_path: "/parent/#{options[:xcconfig_path]}",
        pod_targets: umbrella_targets[0..1],
        pods_project: installer_context.pods_project,
        mangle_prefix: options[:mangle_prefix]
      }
    end

    include_examples 'post install hook'
  end

  context 'only targets defined in options' do
    let(:options) { { targets: ['A', 'B'] } }
    let(:post_install_options) do
      {
        xcconfig_path: "/support_files/#{CocoapodsMangle::NAME}.xcconfig",
        pod_targets: umbrella_targets[0..1],
        pods_project: installer_context.pods_project,
        mangle_prefix: 'Project_'
      }
    end

    include_examples 'post install hook'
  end

  context 'no options' do
    let(:options) { {} }
    let(:post_install_options) do
      {
        xcconfig_path: "/support_files/#{CocoapodsMangle::NAME}.xcconfig",
        pod_targets: umbrella_targets,
        pods_project: installer_context.pods_project,
        mangle_prefix: 'Project_'
      }
    end

    include_examples 'post install hook'
  end
end
