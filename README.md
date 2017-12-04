# cocoapods-mangle

cocoapods-mangle is a CocoaPods plugin which mangles the symbols of your dependencies. Mangling your dependencies' symbols allows more than one copy of a dependency to exist in an app. This is particularly useful for iOS frameworks which do not want to interfere with the host app.

## Installation

    $ gem install cocoapods-mangle

## Usage

Once the gem is installed, cocoapods-mangle can be used by adding it to your `Podfile` like this:

```
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
plugin 'cocoapods-mangle'

target :MyTarget do
  # Dependencies here
end

```
