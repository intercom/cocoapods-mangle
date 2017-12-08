require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/post_install'

describe CocoapodsMangle::PostInstall do
  let(:context) do 
    instance_double('Mangle context')
  end
  let(:subject) do
    CocoapodsMangle::PostInstall.new(context)
  end
  let(:config) { double('config') }

  context '.run!' do
    let(:specs_checksum) { 'checksum' }

    before do
      allow(subject).to receive(:config).and_return(config)
      allow(context).to receive(:specs_checksum).and_return(specs_checksum)
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
      allow(CocoapodsMangle::Config).to receive(:new).with(context).and_return(config)
    end

    it 'creates a config' do
      expect(CocoapodsMangle::Config).to receive(:new).with(context)
      expect(subject.config).to eq(config)
    end
  end
end
