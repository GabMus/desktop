 
# SPDX-FileCopyrightText: (C) 2022 Claudio Cambra <claudio.cambra@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause

{
  description = "A flake for the Nextcloud desktop client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    with flake-utils.lib;
    eachSystem [ "aarch64-linux" "x86_64-linux" ] (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

          nativeBuildInputs = with pkgs; [
            cmake
            qt5.wrapQtAppsHook
          ];

          buildInputs = with pkgs; [
            sqlite
            inotify-tools
            libcloudproviders
            libsecret
            openssl
            pcre

            qt5.qtbase
            qt5.qtquickcontrols2
            qt5.qtsvg
            qt5.qtgraphicaleffects
            qt5.qtdeclarative
            qt5.qttools
            qt5.qtwebengine
            qt5.qtwebsockets

            libsForQt5.breeze-icons
            libsForQt5.qqc2-desktop-style
            libsForQt5.karchive
            libsForQt5.kio

            libsForQt5.qtkeychain
          ];

          packages.default = with pkgs; stdenv.mkDerivation rec {
            inherit nativeBuildInputs buildInputs;
            pname = "nextcloud-client";
            version = "dev";
            src = "desktop/";
            dontStrip = true;
            enableDebugging = true;
            separateDebugInfo = false;
            cmakeFlags = [
                "-DCMAKE_INSTALL_LIBDIR=lib" # expected to be prefix-relative by build code setting RPATH
                "-DNO_SHIBBOLETH=1" # allows to compile without qtwebkit
            ];
            postBuild = ''
                make doc-man
            '';
            postFixup = ''
              wrapProgram "$out/bin/nextcloud" \
                --set LD_LIBRARY_PATH ${lib.makeLibraryPath [ libsecret ]} \
                --set PATH ${lib.makeBinPath [ xdg-utils ]} \
                --set QML_DISABLE_DISK_CACHE "1"
            '';
          };

          apps.default = mkApp {
            name = "nextcloud-client-dev";
            drv = packages.default;
          };

        in {
          inherit packages apps;
          devShell = pkgs.mkShell {
            inherit buildInputs;
            nativeBuildInputs = with pkgs; nativeBuildInputs ++[
              gdb
              qtcreator
            ];
            name = "nextcloud-client-dev-shell";
          };
        }
    );
}
