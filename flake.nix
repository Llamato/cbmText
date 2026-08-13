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
        "riscv64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };
    in {
      packages = forAllSystems (system:
        let pkgs = pkgsFor system; in {
          demo = pkgs.gcc14Stdenv.mkDerivation {
            pname = "cbmtext";
            version = "0.1.0";
            src = pkgs.lib.cleanSource ./.;
            nativeBuildInputs = with pkgs; [
              gnumake
              keepBuildTree
              pkg-config
            ];

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

            installPhase = ''
              mkdir -p $out/bin
              cp build/demo $out/bin/cbmtextdemo
            '';
            
            meta = with pkgs.lib; {
              description = "An OpenGL native space trading game";
              homepage = "http://www.github.com/Llamato/Spacer3000";
              mainProgram = "spacer3000";
              platforms = platforms.unix;
            };
          };
        }
      );
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