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
        "x86_64-darwin"
        "aarch64-darwin"
        "armv7l-linux"
        "riscv64-linux"
      ];

    in
    inputs.flake-utils.lib.eachSystem supportedSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;
        cbmTextBuildInputs = with pkgs; [
          gnumake
        ];
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
        };
      in
      {
        packages = {
          inherit cbmTextDemo;
          default = cbmTextDemo;
          meta = {
            description = "An OpenGL text rendering engine using commodore vdc character roms to make characters";
            license = lib.licenses.mit;
            #maintainers = with lib.maintainers; [ llamato ];

          };
        };
        apps.default = {
          type = "app";
          program = "${cbmTextDemo}/bin/demo";
          platforms = lib.platforms.all;
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
