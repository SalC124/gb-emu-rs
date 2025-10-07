{
  description = "Android + Rust + Dioxus environment (base simplified config)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ rust-overlay.overlays.default ];

        pkgs = import nixpkgs {
          inherit system overlays;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        java = pkgs.jdk17;
        buildToolsVersion = "34.0.0";
        ndkVersion = "25.2.9519653";

        android = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0";
          toolsVersion = "26.1.1";
          platformToolsVersion = "34.0.4";
          buildToolsVersions = [ buildToolsVersion ];
          platformVersions = [ "30" "31" "32" "33" "34" ];
          includeSources = false;
          includeSystemImages = false;
          abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
          includeNDK = true;
          ndkVersions = [ ndkVersion ];
          includeExtras = [ "extras;google;gcm" ];
          systemImageTypes = [ "google_apis_playstore" ];
          includeEmulator = false;
          useGoogleAPIs = false;
          useGoogleTVAddOns = false;
        };

        androidSdkRoot = "${android.androidsdk}/libexec/android-sdk";

        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
          targets = [
            "wasm32-unknown-unknown"
            "aarch64-linux-android"
            "armv7-linux-androideabi"
            "i686-linux-android"
            "x86_64-linux-android"
          ];
        };

        dioxusCli = pkgs.rustPlatform.buildRustPackage rec {
          pname = "dioxus-cli";
          version = "0.6.3";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-wuIJq+UN1q5qYW4TXivq93C9kZiPHwBW5Ty2Vpik2oY=";
          };
          cargoHash = "sha256-L9r/nJj0Rz41mg952dOgKxbDS5u4zGEjSA3EhUHfGIk=";
          nativeBuildInputs = [ pkgs.pkg-config pkgs.cacert ];
          buildInputs = [ pkgs.openssl ];
          OPENSSL_NO_VENDOR = 1;
          doCheck = false;
        };

        rustBuildInputs = [
          pkgs.openssl
          pkgs.rustup
          pkgs.libiconv
          pkgs.pkg-config
          pkgs.mesa
          pkgs.libgbm
          pkgs.libglvnd
          pkgs.xorg.libXi
          pkgs.xorg.libXrandr
          pkgs.xorg.libX11
        ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          pkgs.glib
          pkgs.gtk3
          pkgs.libsoup_3
          pkgs.webkitgtk_4_1
          pkgs.xdotool
        ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
          pkgs.darwin.apple_sdk.frameworks.IOKit
          pkgs.darwin.apple_sdk.frameworks.Carbon
          pkgs.darwin.apple_sdk.frameworks.WebKit
          pkgs.darwin.apple_sdk.frameworks.Security
          pkgs.darwin.apple_sdk.frameworks.Cocoa
        ]);

        # FHS environment to run Android tools
        fhsEnv = pkgs.buildFHSUserEnv {
          name = "dioxus-android-fhs";
          targetPkgs = pkgs: with pkgs; [
            rustToolchain
            dioxusCli
            android.androidsdk
            openjdk
            # Libraries needed for Android tools
            stdenv.cc.cc.lib
            zlib
            libcxx
            libGL
            libglvnd
            fontconfig
            freetype
            xorg.libX11
            xorg.libXext
            xorg.libXi
            xorg.libXrender
            xorg.libXtst
            xorg.libXxf86vm
            # Additional libraries that might be needed
            ncurses5
            libuuid
            expat
            libxcrypt-legacy
            alsa-lib
            at-spi2-atk
            at-spi2-core
            atk
            cairo
            cups
            curl
            dbus
            gtk3
            gdk-pixbuf
            glib
            mesa
            nspr
            nss
            pango
            systemd
            udev
          ] ++ rustBuildInputs;
          multiPkgs = pkgs: with pkgs; [
            stdenv.cc.cc.lib
            zlib
          ] ++ rustBuildInputs;
        };

      in
      {
        devShells.default = pkgs.mkShell {
          name = "dioxus-android-shell";

          buildInputs = [
            java
            android.androidsdk
            rustToolchain
            dioxusCli
            pkgs.gradle
            pkgs.flutter
            pkgs.android-studio
            pkgs.bundletool
          ] ++ rustBuildInputs;

          env = {
            JAVA_HOME = "${java}";
            ANDROID_SDK_ROOT = androidSdkRoot;
            ANDROID_HOME = androidSdkRoot;
            GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/${buildToolsVersion}/aapt2";
          };

          shellHook = ''
            echo ""
            export PATH=$PATH:${androidSdkRoot}/platform-tools
            echo "run 'adb start-server'"
          '';
        };
      });
}
