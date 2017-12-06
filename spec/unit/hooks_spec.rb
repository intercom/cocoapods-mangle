require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/hooks'

def trigger_post_install(installer_context, options)
  post_install_hooks = Pod::HooksManager.registrations[:post_install]
  hook = post_install_hooks.find { |h| h.plugin_name == CocoapodsMangle::NAME }
  hook.block.call(installer_context, options)
end

describe CocoapodsMangle::Hooks do
  let(:installer_context) { instance_double('installer context') }
  let(:options) { double('options') }
  let(:mangle_context) { instance_double('installer context') }
  let(:post_install) { double('post install') }

  before do
    allow(CocoapodsMangle::Context).to receive(:new).with(installer_context, options).and_return(mangle_context)
    allow(CocoapodsMangle::PostInstall).to receive(:new).with(mangle_context).and_return(post_install)
    allow(post_install).to receive(:run!)
  end

  context 'post install' do
    it 'runs the post install action' do
      expect(post_install).to receive(:run!)
      trigger_post_install(installer_context, options)
    end
  end
end
