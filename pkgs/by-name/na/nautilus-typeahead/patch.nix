{ fetchFromGitLab
, nautilus
}:

(fetchFromGitLab {

  domain = "gitlab.gnome.org";
  owner = "albertvaka";
  repo = "nautilus";
  rev = "f5f593bf36c41756a29d5112a10cf7ec70b8eafb";
  hash = "";

  leaveDotGit = true;
  postFetch = ''
    set -x

    tmp_dir=$(mktemp -d)
    mv -T "$out" "$tmp_dir"
    cd "$tmp_dir"

    git remote add upstream https://gitlab.gnome.org/GNOME/nautilus.git
    git fetch --filter=blob:none --tags upstream
    git tag --list
    git format-patch "${nautilus.version}"... --stdout
    git format-patch "${nautilus.version}"... --output="$out"

    set +x
  '';
}).overrideAttrs (finalAttrs: prevAttrs: {
  name = "nautilus-typeahead-${finalAttrs.meta.version}.patch";
  meta.version = "46.1-1"; # labeled by AUR package version
})
