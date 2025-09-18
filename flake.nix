{
  description = "DevEnv init scripts";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        pname = "dev-init-scripts";
        version = "1.0";
        src = self;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          mkdir -p $out/bin
          for f in bin/*; do
            cp "$f" $out/bin/$(basename "$f")
            chmod +x $out/bin/$(basename "$f")
          done
          # Wrap each script so dependecies are in PATH
          for f in $out/bin/*; do
            wrapProgram "$f" \
              --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.cowsay ]}
          done
        '';
      };
    };
}
