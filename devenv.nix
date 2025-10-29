# https://devenv.sh/basics/
{ ... }:
{
  # https://devenv.sh/reference/options/#dotenvenable
  dotenv.enable = true;
  dotenv.disableHint = true;
  git-hooks.hooks = {
    nixfmt-rfc-style.enable = true;
    nixfmt-rfc-style.settings.width = 80;
  };
}
