require 'cocoapods_mangle/context'
require 'cocoapods_mangle/post_install'

module CocoapodsMangle
  # Registers for CocoaPods plugin hooks
  module Hooks
    Pod::HooksManager.register(CocoapodsMangle::NAME, :post_install) do |installer_context, options|
      context = Context.new(installer_context, options)
      post_install = CocoapodsMangle::PostInstall.new(context)
      Pod::UI.titled_section 'Updating mangling' do
        post_install.run!
      end
    end
  end
end
