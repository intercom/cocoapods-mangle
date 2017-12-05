![Intercom](sample/Intercom_logo-github.png)

[![CircleCI](https://circleci.com/gh/intercom/cocoapods-mangle.svg?style=svg)](https://circleci.com/gh/intercom/cocoapods-mangle)

# cocoapods-mangle

cocoapods-mangle is a CocoaPods plugin which mangles the symbols of your dependencies. Mangling your dependencies' symbols allows more than one copy of a dependency to exist in an app. This is particularly useful for iOS frameworks which do not want to interfere with the host app.

## Installation

    $ gem install cocoapods-mangle

## What is mangling?

Mangling or namespacing your dependencies is a way of ensuring that there are no conflicts between multiple copies of the same dependency in an app. This is most useful when developing third-party frameworks.

For example, if you are developing a framework `MyFramework.framework` and you include `AFNetworking` as a dependency, all `AFNetworking` classes are included in your framework's binary:

```
➜ nm -gU MyFramework.framework/MyFramework | grep "_OBJC_CLASS_\$.*AF.*"
00000000000000e0 S _OBJC_CLASS_$_PodsDummy_AFNetworking
00000000000013f0 S _OBJC_CLASS_$_AFNetworkReachabilityManager
0000000000001f20 S _OBJC_CLASS_$_AFSecurityPolicy
000000000000a938 S _OBJC_CLASS_$_AFHTTPBodyPart
000000000000a898 S _OBJC_CLASS_$_AFHTTPRequestSerializer
000000000000a9d8 S _OBJC_CLASS_$_AFJSONRequestSerializer
000000000000a910 S _OBJC_CLASS_$_AFMultipartBodyStream
000000000000aa28 S _OBJC_CLASS_$_AFPropertyListRequestSerializer
000000000000a848 S _OBJC_CLASS_$_AFQueryStringPair
000000000000a8c0 S _OBJC_CLASS_$_AFStreamingMultipartFormData
0000000000004870 S _OBJC_CLASS_$_AFCompoundResponseSerializer
00000000000046e0 S _OBJC_CLASS_$_AFHTTPResponseSerializer
0000000000004820 S _OBJC_CLASS_$_AFImageResponseSerializer
0000000000004730 S _OBJC_CLASS_$_AFJSONResponseSerializer
00000000000047d0 S _OBJC_CLASS_$_AFPropertyListResponseSerializer
0000000000004780 S _OBJC_CLASS_$_AFXMLParserResponseSerializer
```

This means that if an app includes both `MyFramework.framework` and `AFNetworking`, the app will fail to build with an error that looks something like:

```
ld: 16 duplicate symbols for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
```

However, with mangling enabled through cocoapods-mangle, we can see that the `AFNetworking` classes are now prefixed with `MyFramework_`:

```
➜ nm -gU MyFramework.framework/MyFramework | grep "_OBJC_CLASS_\$.*AF.*"
00000000000000e0 S _OBJC_CLASS_$_MyFramework_PodsDummy_AFNetworking
00000000000013f0 S _OBJC_CLASS_$_MyFramework_AFNetworkReachabilityManager
0000000000001f20 S _OBJC_CLASS_$_MyFramework_AFSecurityPolicy
000000000000a938 S _OBJC_CLASS_$_MyFramework_AFHTTPBodyPart
000000000000a898 S _OBJC_CLASS_$_MyFramework_AFHTTPRequestSerializer
000000000000a9d8 S _OBJC_CLASS_$_MyFramework_AFJSONRequestSerializer
000000000000a910 S _OBJC_CLASS_$_MyFramework_AFMultipartBodyStream
000000000000aa28 S _OBJC_CLASS_$_MyFramework_AFPropertyListRequestSerializer
000000000000a848 S _OBJC_CLASS_$_MyFramework_AFQueryStringPair
000000000000a8c0 S _OBJC_CLASS_$_MyFramework_AFStreamingMultipartFormData
0000000000004870 S _OBJC_CLASS_$_MyFramework_AFCompoundResponseSerializer
00000000000046e0 S _OBJC_CLASS_$_MyFramework_AFHTTPResponseSerializer
0000000000004820 S _OBJC_CLASS_$_MyFramework_AFImageResponseSerializer
0000000000004730 S _OBJC_CLASS_$_MyFramework_AFJSONResponseSerializer
00000000000047d0 S _OBJC_CLASS_$_MyFramework_AFPropertyListResponseSerializer
0000000000004780 S _OBJC_CLASS_$_MyFramework_AFXMLParserResponseSerializer
```

The app that includes both `MyFramework.framework` and `AFNetworking` will now build successfully 🎉

## How it works

As demonstrated above, `nm` can be used to inspect the symbols such as classes, constants and selectors in a Mach-O binary. When you run `pod install`, cocoapods-mangle builds your dependencies if they have changed, and parses the output of `nm`. It places this output in an `xcconfig` file that looks something like this:

```
MANGLING_DEFINES = PodsDummy_AFNetworking=MyFramework_PodsDummy_AFNetworking AFNetworkReachabilityManager=MyFramework_AFNetworkReachabilityManager AFSecurityPolicy=MyFramework_AFSecurityPolicy AFHTTPBodyPart=MyFramework_AFHTTPBodyPart AFHTTPRequestSerializer=MyFramework_AFHTTPRequestSerializer AFJSONRequestSerializer=MyFramework_AFJSONRequestSerializer AFMultipartBodyStream=MyFramework_AFMultipartBodyStream AFPropertyListRequestSerializer=MyFramework_AFPropertyListRequestSerializer AFQueryStringPair=MyFramework_AFQueryStringPair AFStreamingMultipartFormData=MyFramework_AFStreamingMultipartFormData AFCompoundResponseSerializer=MyFramework_AFCompoundResponseSerializer AFHTTPResponseSerializer=MyFramework_AFHTTPResponseSerializer AFImageResponseSerializer=MyFramework_AFImageResponseSerializer AFJSONResponseSerializer=MyFramework_AFJSONResponseSerializer AFPropertyListResponseSerializer=MyFramework_AFPropertyListResponseSerializer AFXMLParserResponseSerializer=MyFramework_AFXMLParserResponseSerializer

MANGLED_SPECS_CHECKSUM = 18f61e6e6172fb87ddc7341f3537f30f8c7a3edc
```

This is included in `GCC_PREPROCESSOR_DEFINITIONS` of the `xcconfig` file for every target. All of these symbols will be mangled on subsequent builds.

## Usage

cocoapods-mangle can be used by adding it to your `Podfile` like this:

```
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
plugin 'cocoapods-mangle'

target :MyTarget do
  # Dependencies here
end

```

Now, each time you run `pod install`, cocoapods-mangle updates the `xcconfig` files for all targets to ensure that all symbols in your dependencies are mangled.

The plugin can be optionally configured with `:xcconfig_path`, `:mangle_prefix` or `:targets`. Here is an example:

```
plugin 'cocoapods-mangle', targets: ['MyTarget'],
                           mangle_prefix: 'Prefix_'
                           xcconfig_path: 'path/to/mangle.xcconfig'
```

## Caveats

- cocoapods-mangle will only work for source dependencies. Pre-compiled frameworks cannot be mangled.
- `pod install` will be slower when you change a dependency, particularly if your app/SDK depends on many pods.
- Currently only supports iOS. It should be very straightforward to extend support to macOS, tvOS or watchOS.
- Category mangling may fail if the dependency does not correctly prefix its category selectors (see http://nshipster.com/namespacing/#method-prefixes).
