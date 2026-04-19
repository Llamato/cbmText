{
  description = "An OpenGL text rendering engine using commodore vdc character roms to make characters";

  outputs = { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "armv7l-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in {
      devShells = forAllSystems (system:
        let 
          pkgs = pkgsFor system;
          devTools = with pkgs; [
              gnumake
              gcc
              gdb
              clang-tools
              bear
              bun
            ];
        in let
          defaultShellHook = ''
            CC=${pkgs.gcc}/bin/gcc
            echo "CC:" $CC
            CXX=${pkgs.gcc}/bin/g++
            echo "CXX:" $CXX
          '';
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              (glfw.overrideAttrs { cmakeFlags = [
                (lib.cmakeBool "GLFW_BUILD_WAYLAND" false)
                (lib.cmakeBool "BUILD_SHARED_LIBS" true)
              ];})
              libGL
              libGLU
              mesa
              libglvnd
              libX11
              libc
            ];
            packages = devTools;
            shellHook = defaultShellHook;
          };
        }
      );
    };
}