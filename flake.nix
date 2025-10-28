{
  description = "DevEnv init scripts";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      tag = "1.18.3";
    in
    {
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
              --prefix PATH : ${
                pkgs.lib.makeBinPath [
                  pkgs.cowsay
                  pkgs.gibo
                  pkgs.bat
                  pkgs.jq
                  pkgs.curl
                ]
              }
          done
        '';
      };

      apps.${system}.scout = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "docker-scout-ephemeral" ''
            set -euo pipefail
            PLUGIN_DIR="$PWD/.docker/scout"
            CONFIG_FILE="$PWD/.docker/config.json"
            mkdir -p "$PLUGIN_DIR"
            TAR="$PWD/docker-scout-${tag}.tar.gz"
            BIN="$PLUGIN_DIR/docker-scout"
            if [ ! -x "$BIN" ]; then
              URL="https://github.com/docker/scout-cli/releases/download/v${tag}/docker-scout_${tag}_linux_amd64.tar.gz"
              echo $URL
              ${pkgs.curl}/bin/curl -L "$URL" -o "$TAR"
              mkdir -p "$(dirname "$BIN")"
              ${pkgs.gnutar}/bin/tar -xf "$TAR" -C "$(dirname "$BIN")" docker-scout
              chmod +x "$BIN"
              rm "$TAR"
            fi
                      
            mkdir -p "$(dirname "$CONFIG_FILE")"
            cat > "$CONFIG_FILE" <<EOF
            {
              "cliPluginsExtraDirs": [
                "$(dirname "$BIN")"
              ]
            }
            EOF
            export DOCKER_CONFIG="$PWD/.docker"
            exec ${pkgs.docker}/bin/docker "$@"
          ''
        );
      };
    };
}
