---
title: "Flutter and Rust combined. Creating a plugin to support various operating systems"
date: 2022-09-26T19:27:05+02:00
layout: post
authors:
 - jg
tags:
 - flutter
 - rust
 - method channel
 - ffi
comments: true
---

Both, Flutter and Rust are pretty novel technologies in the industry. Both also introduce a paradigm shift of how to approach portability, a very old and diffcult problem to solve. Portability is diffcult due to lack of common denominator across platforms, devices and operating systems. To achieve it, Flutter comes with a concept of [MethodChannel](https://docs.flutter.dev/development/platform-integration/platform-channels), a cross-boundary interface that allows to write and call platform native code. It then enables seamless integrations that are essential when working with Operating System specific user interface or natively accessing device peripherals. No more tweaks thanks to proper integration mechanisms. Rust, on the the other hand, is getting traction in various ecosystems and there are at least several reasons why it becomes more and more popular as general purpose programming language. Rust is in essence a C-based language with novel concepts and modern tooling supporting the language. It has steep learning curve due to the architectural decisions baked in into the language. However once it is overcame it pays off. One especially interesing characteristic of the language is its adaptability in almost any environment. As a C-based language, program written in Rust can be exposed as a binary to many modern Operating Systems. Not only that, thanks to [Foreign Function Interface (FFI)](https://en.wikipedia.org/wiki/Foreign_function_interface) integration possibilities of Rust-based code, it became viable alternative to write platform agnostic code and expose it through FFI. In other words one Rust library can be consumed by any other C-based language. The core business logic is then encapsulated into one library that is later consumed within platform specific languages. 

This post guides the reader how to benefit from Flutter and Rust collaboration in a best form. When native programming lanugages available in `FlutterMethodChannel` don't come in handy, [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) might be the solution. It allows the use of Rust code in Flutter application through an externally generated library. This tutorial however will not be introducing to the usage of the plugin. It assumes the user is familiar with `flutter_rust_bridge` [documentation](http://cjycode.com/flutter_rust_bridge/) and knows the basics. Moreover, to build for iOS and MacOS it is necessary to have access to Xcode and MacOS device. To build for Windows, Windows OS is needed as well. `flutter_rust_bridge` provided tutorial for Android + Rust plugin so it will not be covered here.

A proof of concept plugin can be found [here](https://github.com/argonAUTHs/flutter_rust_plugin). 

## Initial steps
1. In the root folder of your project create a new directory. It will be later referred here as `$rust_part`.
2. Run `cargo init` inside `$rust_part`. This will create `src` folder and `Cargo.toml` file.
3. In the `src` folder there is one file: `main.rs`. It can be deleted. Create 2 new files called `lib.rs` and `api.rs`. The first one will call all modules from rust project while the other is a module containing all functions that should be bridged to dart.
4. Modify the `api.rs` file and add your library functionality. In this case it will be a simple hello world string function:
    ```
    pub fn hello() -> String {
        return "Hello World!".to_string();
    }
    ```
5. Modify the `lib.rs` file:
```rust=
pub mod api;
```
6. Add the following lines to `Cargo.toml` (Notice: The lib lines may change depending on the platform you are building for. ):
    ```
    [lib]
    crate-type = ["staticlib", "cdylib"]

    [dependencies]
    flutter_rust_bridge = "1"
    ```
7. Run the following commands in `$rust_part`:
    ```
    cargo install flutter_rust_bridge_codegen
    flutter pub add --dev ffigen
    flutter pub add ffi
    flutter pub add flutter_rust_bridge
    cargo install cargo-xcode
    ```
8. Cross compiling targets setup will not be covered here. For more information on the topic please check the recommended `flutter_rust_bridge` documentation ([here](http://cjycode.com/flutter_rust_bridge/template/setup_android.html) is an example of Android target setup).
9. The Rust part is ready to be built. For different targets use:
    - For Android: `cargo ndk -o ../android/src/main/jniLibs build --release`. This command results in two `librust_part.so` files for two Android architectures.
    - For Windows: `cargo build --release` (has to be executed on Windows OS) . **Important:** The `crate-type` in `Cargo.toml` has to be changed to `"dylib"`. In folder `rust_part/target/release` you will find files called `rust_part.dll` and `rust_part.dll.lib`. Remove the `.dll` part from the second one and the Windows files are ready.
    - For iOS: `cargo lipo`. In folder `rust_part/target/universal/release` you will find `librust_part.a` file. 
    - For MacOS: `cargo build --release` (has to be executed on Windows OS) . **Important:** The `crate-type` in `Cargo.toml` has to be changed to `"dylib"`. In folder `rust_part/target/release` you will find file called `librust_part.dylib`.

## iOS

1. Make sure you created support for iOS in your project with `flutter create --platform=ios .`
**Warning:** This command will create all files that are automatically created when making new Flutter project. If for some reason you deleted some of them, you might need to get rid of them again.
2. Run `cargo xcode` in `$rust_part`. This will create a `.xcodeproj` file. This file will be soon opened in Xcode to change symbol stripping method.
3. Run `cargo lipo` in `$rust_part`. To specify target, run with `-p $target` flag. To build a release library (smaller in size), use `--release` flag.
4. Next, run the generator: `flutter_rust_bridge_codegen --rust-input $rust_part/src/api.rs --dart-output lib/bridge_generated.dart --c-output ios/bridge_generated.h`
Actually, the location of `bridge_generated.h` is not that important, as it is created only to have its content appended to another file.
5. Then create a symbolic link in iOS folder to `.a` library: `ln -s ../$rust_part/target/universal/release/librust_part.a`
You may also move the `.a` file to the `ios` folder, this way there is no need for the symlink as the library is directly accessible.
6. Then append the contents of `bridge_generated.h` to `/ios/Classes/$Plugin.h`: `cat ios/bridge_generated.h >> ios/Classes/$Plugin.h`
7. Then add in `ios/Classes/.swift` file dummy method: 
    ```
    public func dummyMethodToEnforceBundling() {
      // This will never be executed
      dummy_method_to_enforce_bundling();
    }
    ```
8. Next, edit `podspec` file and add the following lines:
```
  s.public_header_files = 'Classes**/*.h'
  s.static_framework = true
  s.vendored_libraries = "**/*.a"
```
9. Next, remember to set the strip style to non global symbols on both the `.xcodeproj` in `$rust_part` and `.xcodeworkspace` in example (if you want to run the example).
11. Remember to edit `pubspec.yaml` file so it has following structure:
    ```
    plugin:
        platforms:
          android:
            package: com.example.flutter_rust_plugin
            pluginClass: FlutterRustPlugin
          ios:
            pluginClass: FlutterRustPlugin
    ```
The `pluginClass` here for iOS stands for `.h` file in Classes folder.

### iOS Troubleshooting
- run `pod install` in ios folder with Runner (helps with `module not found` error in Xcode)
- to run a different dart file than `main.dart` edit `FLUTTER_TARGET` in Xcode in Runner Build Settings.
- check `iOS Deployment Target`, 9.0 might be too old for some releases.


## MacOS
This tutorial is made for a multiplatform project and it assumes the iOS support is already working.
1. Add support for MacOS in your project by executing `flutter create --platform=macos .`
**Warning:** This command will create all files that are automatically created when making new Flutter project. If for some reason you deleted some of them, you might need to get rid of them again.

2. To link your Rust library with MacOS, `.dylib` file type is necessary. To generate it, edit `Cargo.toml`, so that it has following structure:
    ```
    [lib]
    crate-type = ["dylib"]
    ```
Then run `cargo build` in your `$crate` directory. Remember to use the flag `--release` to make the lib much smaller.

3. Move your `.dylib` file to `macos` folder in your project. 
4. In `.swift` file in `macos/Classes` add the dummy method (more about it in `flutter_rust_bridge` documentation):
    ```
    public func dummyMethodToEnforceBundling() {
        // This will never be executed
        dummy_method_to_enforce_bundling()
    }
    ```

5. Don't forget to edit `pubspec.yaml` and add the MacOS support:
    ```
    plugin:
        platforms:
          macos: 
            pluginClass: FlutterRustPlugin
    ```

6. Edit the `.podspec` file and add following lines:
    ```
    s.vendored_libraries = "**/*.dylib"
    s.public_header_files = 'Classes**/*.h'
    s.static_framework = true
    ```

7. Copy the `bridge_generated.h` file from `ios` folder to `macos/Classes`. This file has been generated when enabling support for iOS. To generate it, run: `flutter_rust_bridge_codegen --rust-input $rust_part/src/api.rs --dart-output lib/bridge_generated.dart --c-output macos/Classes/bridge_generated.h`
 

### MacOS Troubleshooting
- If you run into `no such module` error while running the example, enter `example/macos` folder in project and execute `pod install` in the command line. This installs the missing module.
- If during testing the example you run into `cannot find 'dummy_method_to_enforce_bundling' in scope`, run `pod update`.
- For other errors, try `pod deintegrate` and `pod install` to reinstall pods.
- Try deleting all folders from `/Users/<your username>/Library/Developer/Xcode/DerivedData` and cleaning your build folder.

## Windows
This part of the tutorial assumes the user has generated library files `.dll` and `.lib` as described in Initial steps. 
1. If your plugin project does not have Windows support activated, execute `flutter create --platform=windows` in project root folder:

**Warning:** This command will create all files that are automatically created when making new Flutter project. If for some reason you deleted some of them, you might need to get rid of them again.

2. Make a new folder under created in previous point `windows` directory, let us refer to it by `$crate`.
3. Place the `.dll` and `.lib` files in `$crate` directory and change their names to `$crate.dll` and `$crate.lib`.
4. In your `$crate` directory create a new file, `CMakeLists.txt`. Append the following lines to the file:
    ```
    include(../../cmake/$crate.cmake)

    set_property(TARGET ${CRATE_NAME} PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/$crate.dll")
    set_property(TARGET ${CRATE_NAME} PROPERTY IMPORTED_IMPLIB "${CMAKE_CURRENT_SOURCE_DIR}/$crate.lib")
    ```
The included `$crate.cmake` file will be created in the next steps.

5. In your root folder, create `cmake` directory. 
6. Under `cmake` directory create `$crate.cmake` file. Append the following lines to the file:
    ```
    message("-- Linking Rust")
    set(CRATE_NAME "$crate")
    set(CRATE_NAME ${CRATE_NAME} PARENT_SCOPE)
    if(CRATE_STATIC)
      add_library(${CRATE_NAME} STATIC IMPORTED GLOBAL)
    else()
      add_library(${CRATE_NAME} SHARED IMPORTED GLOBAL)
    endif()
    ```

7. Under `cmake` directory create `main.cmake` file. Append the following lines to the file:
    ```
    add_subdirectory($crate)
    target_link_libraries(${PLUGIN_NAME} PRIVATE ${CRATE_NAME})
    ```
8. Edit the `windows/CMakeLists.txt` file. Add the following lines:
    ```
    include(../cmake/main.cmake)
    ```
Put this line after `target_link_libraries` line.
    ```
# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
    set(flutter_rust_plugin_bundled_libraries
      "$<TARGET_FILE:${CRATE_NAME}>"
      PARENT_SCOPE
    )
    ```
Here, change `""` to `"$<TARGET_FILE:${CRATE_NAME}>"`.

9. Don't forget to declare support for windows in `pubspec.yaml` file:
    ```
    plugin:
        platforms:
          android:
            package: com.example.flutter_rust_plugin
            pluginClass: FlutterRustPlugin
          windows:
            pluginClass: FlutterRustPluginCApi
    ```


### Integration with Dart
- Your `.lib` folder should have a similar structure (old plugin template):
    ```
    ├── lib
        ├── bridge_generated.dart
        └── flutter_rust_plugin.dart
    ```
Where `bridge_generated.dart` is a file generated using `flutter_rust_bridge_codegen` and `flutter_rust_plugin.dart` is the main plugin file. For more information on flutter plugin check out the official [documentation](https://docs.flutter.dev/development/packages-and-plugins/developing-packages).
- `flutter_rust_plugin.dart` file contains all methods that will be available in the plugin for the users. The libraries is loaded there. Here is an example of code used to load the libraries:
    ```
    static const base = 'rust_part';
    static final path = Platform.isWindows? '$base.dll' : 'lib$base.so';
    static late final dylib = Platform.isIOS
          ? DynamicLibrary.process()
          : Platform.isMacOS
          ? DynamicLibrary.executable()
          : DynamicLibrary.open(path);
      static late final api = RustPartImpl(dylib);
    ```
The `RustPartImpl` is the name of the class in `bridge_generated.dart`, the one class that extends `FlutterRustBridgeBase`. In order to call the method from library, use:
```dart=
await api.methodName();
```

***
### References
- iOS: This tutorial was created using the official documentation of [flutter_rust_bridge](http://cjycode.com/flutter_rust_bridge/integrate.html) and [mozilla github post](https://mozilla.github.io/firefox-browser-architecture/experiments/2017-09-06-rust-on-ios.html). If something is not clear, checking out these sources might help you.
- Windows: This tutorial was created using the official documentation of [flutter_rust_bridge](http://cjycode.com/flutter_rust_bridge/integrate.html) and [this](https://github.com/mouEsam/rust_cryptor) proof of concept for Flutter+Rust plugin. If something is not clear, checking out these sources might help you. 
