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
      packages.${system} = {
        default = pkgs.stdenv.mkDerivation {
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

        # minio-stu = pkgs.symlinkJoin {
        #   name = "minio-stu";
        #   paths = with pkgs; [
        #     minio-client
        #     stu
        #   ];
        #   buildInputs = [ pkgs.makeWrapper ];
        #   postBuild = ''
        #     for bin in ${pkgs.minio-client}/bin/* ${pkgs.stu}/bin/*; do
        #       if [ -f "$bin" ]; then
        #         wrapProgram "$out/bin/$(basename "$bin")" \
        #           --prefix PATH : $out/bin
        #       fi
        #     done
        #   '';
        # };
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

#     scripts.ensure-docker-tar = {
#     scripts.ensure-docker-tar = {
#   exec = ''
#     if [[ ! -f ".docker/$APP_NAME.tar" ]]; then
#       echo "▶ Docker tar not found, building..."
#       dev-compose-tar $APP_NAME
#     else
#       echo "✓ Docker tar exists: .docker/$APP_NAME.tar"
#     fi
#   '';
# };
# scripts.docker-scout = {
#   exec = ''
#     ensure-docker-tar
#     if [[ -z "''${DOCKER_SCOUT_HUB_USER:-}" ]]; then
#       echo "❌ DOCKER_SCOUT_HUB_USER environment variable is not set" >&2
#       echo "Please set it before running docker scout commands" >&2
#       exit 1
#     fi
#     if [[ -z "''${DOCKER_SCOUT_HUB_PASSWORD:-}" ]]; then
#       echo "❌ DOCKER_SCOUT_HUB_PASSWORD environment variable is not set" >&2
#       echo "Please set it before running docker scout commands" >&2
#       exit 1
#     fi
#     nix run github:mshnwq/devenv-init#scout --no-write-lock-file -- scout "$@"
#   '';
# };
# scripts.docker-scout-cves = {
#   description = "Check docker image CVES";
#   exec = ''
#     echo "▶ Scanning for CVEs..."
#     docker-scout cves "archive://.docker/$APP_NAME.tar" \
#       # --format markdown --output "$APP_NAME.cves.md"
#       # --format sarif --output "$APP_NAME.cves.sarif"
#       # --format gitlab --output "$APP_NAME.cves.gitlab"
#       # --format spdx --output "$APP_NAME.cves.spdx"
#     echo "✓ CVE report saved to $APP_NAME.cves"
#   '';
# };
# scripts.docker-scout-sbom = {
#   description = "Generate Software Bill of Material";
#   exec = ''
#     echo "▶ Generating SBOM..."
#     docker-scout sbom "archive://.docker/$APP_NAME.tar" \
#       --format list --output "$APP_NAME.sbom.list"
#       # --format json --output "$APP_NAME.sbom.json"
#       # --format spdx --output "$APP_NAME.sbom.spdx"
#     echo "✓ SBOM saved to $APP_NAME.sbom"
#   '';
# };
