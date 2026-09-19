{
  description = "An OpenGL text rendering engine using commodore vdc character roms to make characters";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "armv7l-linux"
        "riscv64-linux"
      ];

    in
    inputs.flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        cbmTextDescription = "An OpenGL text rendering engine using commodore vdc character roms to make characters";
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        cbmTextBuildInputs = with pkgs; [
          gnumake
        ];
        cbmTextMeta = {
          description = cbmTextDescription;
          license = lib.licenses.mit;
          platforms = lib.platforms.unix;
          #maintainers = with lib.maintainers; [ llamato ];
        };
        cbmTextNativeBuildInputs = with pkgs; [
          (glfw.overrideAttrs {
            cmakeFlags = [
              (lib.cmakeBool "GLFW_BUILD_WAYLAND" false)
              (lib.cmakeBool "BUILD_SHARED_LIBS" true)
            ];
          })
          libGL
          libGLU
          mesa
          libglvnd
          libX11
          libc
        ];
        cbmTextDemo = pkgs.stdenv.mkDerivation {
          name = "cbmTextDemo";
          version = "0.0.1";
          src = ./.;
          buildInputs = cbmTextBuildInputs;
          nativeBuildInputs = cbmTextNativeBuildInputs;
          installFlags = [ "PREFIX=${placeholder "out"}" ];
          meta = cbmTextMeta;
        };
      in
      {
        packages = {
          inherit cbmTextDemo;
          default = cbmTextDemo;
        };
        apps.default = {
          type = "app";
          program = "${cbmTextDemo}/bin/demo";
          meta = cbmTextMeta;
        };
        devShells.default = pkgs.mkShell {
          inputsFrom = [ cbmTextDemo ];
          packages = with pkgs; [
            gcc
            gdb
            clang-tools
            bear
          ];
        };
      }
    );
}
