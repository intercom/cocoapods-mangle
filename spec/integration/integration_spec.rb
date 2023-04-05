require File.expand_path('../../spec_helper', __FILE__)
require 'tmpdir'
require 'cocoapods_mangle/config'

def defines_from_xcconfig(xcconfig_path)
  xcconfig = Xcodeproj::Config.new(File.new(xcconfig_path)).to_hash
  
  puts xcconfig
  xcconfig[CocoapodsMangle::Config::MANGLING_DEFINES_XCCONFIG_KEY].split(' ')
end

def build_sample
  `xcodebuild -workspace "Mangle Integration.xcworkspace" -scheme "Mangle Integration" -sdk iphonesimulator build`
  $?.success?
end

RSpec.shared_examples 'mangling integration' do
  it 'installs and mangles all expected symbols' do
    Dir.chdir project_dir

    # Calling the command directly here rather than through the Ruby API
    # because the CocoaPods Ruby API seems to keep some state between installs
    `bundle exec pod install`
    pod_install_success = $?.success?
    expect(pod_install_success).to be_truthy

    xcconfig_path = File.join(project_dir, "Pods/Target Support Files/#{CocoapodsMangle::NAME}.xcconfig")
    expect(defines_from_xcconfig(xcconfig_path)).to match_array(expected_defines)
    expect(build_sample).to be_truthy
  end
end

describe CocoapodsMangle do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:project_dir) { File.join(tmp_dir, 'project') }
  let(:pod_dir) { File.join(tmp_dir, 'pod') }

  before(:each) do
    fixtures_dir = File.expand_path("#{File.dirname(__FILE__)}/../fixtures")
    FileUtils.copy_entry(File.join(fixtures_dir, 'project'), project_dir)
    FileUtils.copy_entry(File.join(fixtures_dir, podpsec_fixture_dir), pod_dir)
    File.open(File.join(project_dir, 'Podfile'), 'w') do |podfile|
      podfile.write(podfile_contents)
    end
  end

  context "with a Swift pod" do
    let(:podpsec_fixture_dir) { "swift-pod" }

    context 'without frameworks' do
      let(:podfile_contents) do
        <<~PODFILE
          platform :ios, '10.0'
          plugin 'cocoapods-mangle'
          target 'Mangle Integration' do
            pod 'ManglePod', path: '../pod'
            pod 'lottie-ios'
          end
        PODFILE
      end
      let(:expected_defines) do
        %w[
          PodsDummy_ManglePod=Mangle_Integration_PodsDummy_ManglePod
          PodsDummy_lottie_ios=Mangle_Integration_PodsDummy_lottie_ios
        ]
      end
  
      include_examples 'mangling integration'
    end

    context 'with frameworks' do
      let(:podfile_contents) do
        <<~PODFILE
          platform :ios, '10.0'
          use_frameworks!
          plugin 'cocoapods-mangle'
          target 'Mangle Integration' do
            pod 'ManglePod', path: '../pod'
          end
        PODFILE
      end
      let(:expected_defines) do
        %w[
          ManglePodVersionNumber=Mangle_Integration_ManglePodVersionNumber
          ManglePodVersionString=Mangle_Integration_ManglePodVersionString
          PodsDummy_ManglePod=Mangle_Integration_PodsDummy_ManglePod
        ]
      end
  
      include_examples 'mangling integration'
    end
  end

  context "with an Objective-C pod" do
    let(:podpsec_fixture_dir) { "objc-pod" }

    context 'without frameworks' do
      let(:podfile_contents) do
        <<~PODFILE
          platform :ios, '10.0'
          plugin 'cocoapods-mangle'
          target 'Mangle Integration' do
            pod 'ManglePod', path: '../pod'
          end
        PODFILE
      end
      let(:expected_defines) do
        %w[
          PodsDummy_ManglePod=Mangle_Integration_PodsDummy_ManglePod
          CPMObject=Mangle_Integration_CPMObject
          CPMConstant=Mangle_Integration_CPMConstant
          CPMStringFromIntegerFunction=Mangle_Integration_CPMStringFromIntegerFunction
          cpm_doSomethingWithoutParams=Mangle_Integration_cpm_doSomethingWithoutParams
          cpm_doSomethingWithParam=Mangle_Integration_cpm_doSomethingWithParam
        ]
      end
  
      include_examples 'mangling integration'
    end
  
    context 'with frameworks' do
      let(:podfile_contents) do
        <<~PODFILE
          platform :ios, '10.0'
          use_frameworks!
          plugin 'cocoapods-mangle'
          target 'Mangle Integration' do
            pod 'ManglePod', path: '../pod'
          end
        PODFILE
      end
      let(:expected_defines) do
        %w[
          ManglePodVersionNumber=Mangle_Integration_ManglePodVersionNumber
          ManglePodVersionString=Mangle_Integration_ManglePodVersionString
          PodsDummy_ManglePod=Mangle_Integration_PodsDummy_ManglePod
          CPMObject=Mangle_Integration_CPMObject
          CPMConstant=Mangle_Integration_CPMConstant
          CPMStringFromIntegerFunction=Mangle_Integration_CPMStringFromIntegerFunction
          cpm_doSomethingWithoutParams=Mangle_Integration_cpm_doSomethingWithoutParams
          cpm_doSomethingWithParam=Mangle_Integration_cpm_doSomethingWithParam
        ]
      end
  
      include_examples 'mangling integration'
    end
  end
end
