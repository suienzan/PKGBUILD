#! /usr/bin/bash

cd mplus-1-code-nerd-font || exit

git fetch origin && git reset --hard origin/master >>/dev/null 2>&1

get_mplus1code_update_time() {
  curl -s "https://api.github.com/repos/coz-m/MPLUS_FONTS/commits?path=fonts%2Fttf%2FMplus1Code-Regular.ttf" |
    jq -r '.[0].commit.committer.date' |
    sed -r 's/[-:TZ]//g'
}

TIME="$(get_mplus1code_update_time)"

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"v([^"]+)".*/\1/'
}

NERD_VERSION="$(get_latest_release ryanoasis/nerd-fonts)"

VERSION="$TIME".${NERD_VERSION//-/_}
echo "Version: $VERSION"
CURRENT="$(grep -Po '(?<=pkgver=)[^&]*' PKGBUILD)"

if [ "$VERSION" = "$CURRENT" ]; then
  echo "No new version."
else
  sed -i -E "s/(_mplusver=)(.*)/\1$TIME/" PKGBUILD
  sed -i -E "s/(pkgver=)(.*)/\1$VERSION/" PKGBUILD
  sed -i -E "s/(pkgrel=)(.*)/\11/" PKGBUILD
  sed -i -E "s|(FontPatcher-v)(.*)(.zip::.*nerd-fonts/releases/download/)(.*)(/FontPatcher.zip)|\1$NERD_VERSION\3v$NERD_VERSION\5|" PKGBUILD
  sed -i '/epoch=1/d' PKGBUILD

  updpkgsums || (
    git add . &
    git reset --hard HEAD &
    exit 1
  )

  makepkg --printsrcinfo >.SRCINFO
  makepkg -f || exit 1
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
