# flake.nix
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

      glimNew = pkgs.rustPlatform.buildRustPackage {
        pname = "glim";
        version = "git-f141972";
        src = pkgs.fetchFromGitHub {
          owner = "mshnwq";
          repo = "glim";
          rev = "f1419721699e400f9ca035cfd5b4fb72c58c6410";
          hash = "sha256-vNJn2Xf8KBZMDD3hK0SXLQ9+84hDid2+NHNviU3oCGs=";
        };
        cargoHash = "sha256-9DxUgv10cSsTlwqTJWtNxcd/hbS6pGZ+XCPjL1wbCh8=";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ];
      };

      glimOld = pkgs.rustPlatform.buildRustPackage {
        pname = "glim";
        version = "git-cd53dae";
        src = pkgs.fetchFromGitHub {
          owner = "junkdog";
          repo = "glim";
          rev = "cd53dae9985c16c49172ad0583fc2e4e2fe223dc";
          hash = "sha256-yAymON+o2slcyCpEq5prkffUelW5jV3I9JSJuQc6+jc=";
        };
        cargoHash = "sha256-9DxUgv10cSsTlwqTJWtNxcd/hbS6pGZ+XCPjL1wbCh8=";
        nativeBuildInputs = [ pkgs.pkg-config ];
        buildInputs = [ pkgs.openssl ];
      };

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

        glim = pkgs.writeShellApplication {
          name = "glim";
          text = ''
            if [ -f .env ]; then
              export "$(grep -v '^#' .env | grep -E 'GLIM_TOKEN|GLIM_SEARCH_FILTER' | xargs)"
            fi
            base_config="${pkgs.writeText "glim.toml" ''
              gitlab_url = "https://gitlab.com/api/v4"
              gitlab_token = ""
              search_filter = ""
              animations = true
            ''}"
            config="$base_config"
            if [ -n "$GLIM_TOKEN" ] || [ -n "$GLIM_FILTER" ]; then
              config=$(mktemp)
              cp "$base_config" "$config"
              if [ -n "$GLIM_TOKEN" ]; then
                sed -i "s|gitlab_token = \"\"|gitlab_token = \"$GLIM_TOKEN\"|" "$config"
              fi
              if [ -n "$GLIM_FILTER" ]; then
                sed -i "s|search_filter = \"\"|search_filter = \"$GLIM_FILTER\"|" "$config"
              fi
            fi
            exec ${glimOld}/bin/glim --config "$config" "$@"
          '';
        };

        sparta = pkgs.stdenv.mkDerivation {
          pname = "spa_nix";
          version = "git-8bfa2bf";
          src = pkgs.fetchFromGitHub {
            owner = "sparta";
            repo = "sparta";
            rev = "8bfa2bfb77207d1eded8f1309d224f0bb45329d1";
            hash = "sha256-LJLMPQC5G1Vrpa129v03k8Gcai85qhmQHlAATQnQrpA=";
          };
          nativeBuildInputs = [ pkgs.cmake ];
          buildInputs = [ pkgs.mpi ];
          cmakeFlags = [
            "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
            "-DSPARTA_MACHINE=nix"
          ];
          sourceRoot = "source";
          preConfigure = ''
            cd cmake
          '';
        };

      };

      apps.${system}.scout =
        let
          tag = "1.18.3";
        in
        {
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
