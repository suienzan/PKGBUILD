#! /usr/bin/bash

cd mplus-1-code-nerd-font || exit

git fetch origin && git reset --hard origin/master >>/dev/null 2>&1

get_mplus1code_update_time() {
  curl -s "https://api.github.com/repos/coz-m/MPLUS_FONTS/commits?path=fonts%2Fttf%2FMplus1Code-Regular.ttf" |
    jq -r '.[0].commit.committer.date' |
    sed -r 's/[-:TZ]//g'
}
TIME="$(get_mplus1code_update_time)"
[[ -z "$TIME" ]] && {
  echo "Error get version"
  exit 1
}

get_nerd_version() {
  curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases |
    jq -r 'map(select(.prerelease)) | first | .tag_name'
}
NERD_VERSION="$(get_nerd_version)"
[[ -z "$NERD_VERSION" ]] && {
  echo "Error get nerd version"
  exit 1
}

VERSION="$TIME".${NERD_VERSION//-/_}
echo "Version: $VERSION"
CURRENT="$(grep -Po '(?<=pkgver=)[^&]*' PKGBUILD)"

if [ "$VERSION" = "$CURRENT" ]; then
  echo "No new version."
else
  sed -i "s/\(_mplusver=\)\(.*\)/\1$TIME/" PKGBUILD
  sed -i "s/\(pkgver=\)\(.*\)/\1$VERSION/" PKGBUILD
  sed -i -E "s/(.*nerd-fonts\/releases\/download\/)(.*)(\/FontPatcher.zip)/\1$NERD_VERSION\3/" PKGBUILD
  sed -i '/epoch=1/d' PKGBUILD

  updpkgsums || (
    git add . &
    git reset --hard HEAD &
    exit 1
  )

  makepkg --printsrcinfo >.SRCINFO
  makepkg -f
  git add .
  git commit -m v"$VERSION"
  git push

  cd ..
  repo="${PWD##*/} v$VERSION"

  git add .
  git commit -m "$repo"
  git push

  echo version "$repo" 'done'
fi
