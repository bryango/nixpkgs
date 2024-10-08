# Autogenerated by maintainers/scripts/bootstrap-files/refresh-tarballs.bash as:
# $ ./refresh-tarballs.bash --targets=s390x-unknown-linux-gnu
#
# Metadata:
# - nixpkgs revision: 0a7eaa55ccaa5103f44a9a4e3e0b06e5314a6401
# - hydra build: https://hydra.nixos.org/job/nixpkgs/cross-trunk/bootstrapTools.s390x-unknown-linux-gnu.build/latest
# - resolved hydra build: https://hydra.nixos.org/build/268609502
# - instantiated derivation: /nix/store/x66rrb9wv612n37bj6iggr2vg313hs77-stdenv-bootstrap-tools-s390x-unknown-linux-gnu.drv
# - output directory: /nix/store/ijkl5anf7mx1p3whdkxv4qs5crf6ic35-stdenv-bootstrap-tools-s390x-unknown-linux-gnu
# - build time: Mon, 05 Aug 2024 17:28:42 +0000
{
  bootstrapTools = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv/s390x-unknown-linux-gnu/0a7eaa55ccaa5103f44a9a4e3e0b06e5314a6401/bootstrap-tools.tar.xz";
    hash = "sha256-HYooNwkStp9Q1nZOw9celEiQPWwU7iSHP1iaxodBv1g=";
  };
  busybox = import <nix/fetchurl.nix> {
    url = "http://tarballs.nixos.org/stdenv/s390x-unknown-linux-gnu/0a7eaa55ccaa5103f44a9a4e3e0b06e5314a6401/busybox";
    hash = "sha256-8BUGvp0gm4v3qBemF/kTVVCsu3ydWLGRVPulBsAL+MI=";
    executable = true;
  };
}
