{
  pkgs,
  ...
}:
{
  dotenv.enable = true;
  dotenv.disableHint = true;
  # enterShell = ''
  #   source ./bin/init-s3
  # '';
  # scripts.s3 = {
  #   exec = ''
  #     stu --endpoint-url $S3_URL "$@"
  #   '';
  # };
  # packages = with pkgs; [
  #   minio-client
  #   stu
  # ];
  git-hooks.hooks = {
    nixfmt-rfc-style = {
      enable = true;
      settings = {
        width = 80;
      };
    };
  };
}
