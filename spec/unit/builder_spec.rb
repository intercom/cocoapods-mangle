require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/builder'

describe CocoapodsMangle::Builder do
  let(:pods_project_path) { 'path/to/Pods.xcodeproj' }
  let(:pod_target_labels) { %w[Pod-A Pod-B] }
  let(:subject) { CocoapodsMangle::Builder.new(pods_project_path, pod_target_labels) }

  context '.build!' do
    before do
      allow(FileUtils).to receive(:remove_dir).with(CocoapodsMangle::Builder::BUILD_DIR, true)
    end

    it 'builds' do
      expect(FileUtils).to receive(:remove_dir).with(CocoapodsMangle::Builder::BUILD_DIR, true)
      expect(subject).to receive(:build_target).with('Pod-A')
      expect(subject).to receive(:build_target).with('Pod-B')
      subject.build!
    end
  end

  context '.binaries_to_mangle' do
    let(:static_binaries) { %w[path/to/staticA.a path/to/staticB.a] }
    let(:frameworks) { %w[path/to/FrameworkA.framework path/to/FrameworkB.framework] }
    let(:framework_binaries) do
      frameworks.map { |path| "#{path}/#{File.basename(path, '.framework')}" }
    end
    before do
      allow(Dir).to receive(:glob)
        .with("#{CocoapodsMangle::Builder::BUILT_PRODUCTS_DIR}/**/*.a")
        .and_return(static_binaries + ['path/to/libPods-A.a'])
      allow(Dir).to receive(:glob)
        .with("#{CocoapodsMangle::Builder::BUILT_PRODUCTS_DIR}/**/*.framework")
        .and_return(frameworks + ['path/to/Pods_A.framework'])
    end

    it 'gives the static and framework binaries' do
      binaries = static_binaries + framework_binaries
      expect(subject.binaries_to_mangle).to match_array(binaries)
    end
  end
end
