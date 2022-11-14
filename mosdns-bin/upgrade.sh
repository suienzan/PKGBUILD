#! /usr/bin/bash

cd mosdns-bin || exit

git fetch origin && git reset --hard origin/master >>/dev/null 2>&1

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"v([^"]+)".*/\1/'
}

VERSION="$(get_latest_release IrineSistiana/mosdns)"
echo "Version: $VERSION"
CURRENT="$(grep -Po '(?<=pkgver=)[^&]*' PKGBUILD)"

NEW_MAJOR=${VERSION%%.*}
CURRENT_MAJOR=${CURRENT%%.*}

if [ "$NEW_MAJOR" != "$CURRENT_MAJOR" ]; then
  echo "New major version."
elif [ "$VERSION" = "$CURRENT" ]; then
  echo "No new version."
else
  sed -i -E "s/(pkgver=)(.*)/\1$VERSION/" PKGBUILD
  sed -i -E "s/(pkgrel=)(.*)/\11/" PKGBUILD

  updpkgsums || (
    git add . &
    git reset --hard HEAD &
    exit 1
  )

  makepkg --printsrcinfo >.SRCINFO
  makepkg -f || exit 1
  git add .
  git commit -m v"$VERSION"
  git push origin HEAD:master

  cd ..
  repo="${PWD##*/} v$VERSION"

  git add .
  git commit -m "$repo"
  git push

  echo version "$repo" 'done'
fi
