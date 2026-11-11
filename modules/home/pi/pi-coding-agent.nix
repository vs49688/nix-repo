{
  lib,
  pi-coding-agent,
}:

##
# 1.5.0's postInstall copies every workspace into node_modules but not
# `packages/schema`, the new home of `@earendil-works/pi-schema` -- then
# deletes its symlink as dangling. pi-ai imports it at load, so `pi --version`
# works while every extension and every subagent dies with
# ERR_MODULE_NOT_FOUND. Copy it the way the other workspaces are copied; the
# extra lines do nothing once upstream's postInstall mentions pi-schema.
# https://github.com/NixOS/nixpkgs/issues/583791 (fix in #582756)
##
pi-coding-agent.overrideAttrs (previous: {
  postInstall = previous.postInstall + lib.optionalString
    (!lib.hasInfix "pi-schema" previous.postInstall) ''
      nm="$out/lib/node_modules/pi-monorepo/node_modules"
      cp -r packages/schema "$nm/@earendil-works/pi-schema"
    '';
})
