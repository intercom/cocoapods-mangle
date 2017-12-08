require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods_mangle/defines'

describe CocoapodsMangle::Defines do
  let(:non_global_defined_symbols) do
    File.read("#{File.dirname(__FILE__)}/../fixtures/non_global_defined_symbols.txt").split("\n")
  end
  let(:all_defined_symbols) do
    File.read("#{File.dirname(__FILE__)}/../fixtures/all_defined_symbols.txt").split("\n")
  end
  let(:defines) { CocoapodsMangle::Defines.mangling_defines('Prefix_', ['A.a', 'B.a']) }

  before do
    allow(CocoapodsMangle::Defines).to receive(:run_nm).with(['A.a', 'B.a'], '-gU').and_return(non_global_defined_symbols)
    allow(CocoapodsMangle::Defines).to receive(:run_nm).with(['A.a', 'B.a'], '-U').and_return(all_defined_symbols)
  end

  context 'Class mangling' do
    let(:expected_classes) do
      %w[
        PINDataTaskOperation
        PINProgressiveImage
        PodsDummy_PINRemoteImage
        PINRemoteImageCallbacks
        PINRemoteImageCategoryManager
        PINRemoteImageDownloadTask
        PINRemoteImageManager
        PINTaskQOS
        PINRemoteImageManagerResult
        PINRemoteImageProcessorTask
        PINRemoteImageTask
        PINRemoteLock
        PINURLSessionManager
        FLAnimatedImage
        FLWeakProxy
        FLAnimatedImageView
      ]
    end

    it 'should mangle the classes' do
      expected_classes.each do |class_name|
        expect(defines).to include("#{class_name}=Prefix_#{class_name}")
      end
    end
  end

  context 'Constant mangling' do
    let(:expected_constants) do
      %w[
        PINRemoteImageManagerErrorDomain
        PINImageJPEGRepresentation
        PINImagePNGRepresentation
        pin_UIImageOrientationFromImageSource
        dataTaskPriorityWithImageManagerPriority
        operationPriorityWithImageManagerPriority
        kFLAnimatedImageDelayTimeIntervalMinimum
      ]
    end

    it 'should mangle the constants' do
      expected_constants.each do |const|
        expect(defines).to include("#{const}=Prefix_#{const}")
      end
    end
  end

  context 'Category selector mangling' do
    let(:expected_non_property_selectors) do
      %w[
        pin_cancelImageDownload
        pin_clearImages
        pin_downloadImageOperationUUID
        pin_ignoreGIFs
        pin_setDownloadImageOperationUUID
        pin_setImageFromURL
        pin_setImageFromURLs
        pin_setPlaceholderWithImage
        pin_updateUIWithImage
        pin_isGIF
        pin_decodedImageWithCGImageRef
        pin_decodedImageWithData
        pin_addOperationWithQueuePriority
        logStringFromBlock
        setLogBlock
      ]
    end

    it 'should mangle the category selectors' do
      expected_non_property_selectors.each do |sel|
        expect(defines).to include("#{sel}=Prefix_#{sel}")
      end
    end

    it 'should mangle the category property selectors' do
      expect(defines).to include('pin_updateWithProgress=Prefix_pin_updateWithProgress')
      expect(defines).to include('setPin_updateWithProgress=setPrefix_pin_updateWithProgress')
    end
  end
end
