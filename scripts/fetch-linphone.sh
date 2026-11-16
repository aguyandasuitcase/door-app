#!/bin/bash
# Downloads the Linphone iOS SDK from download.linphone.org (the git host is often unreachable)
set -e
V="${LINPHONE_VERSION:-5.5.41}"
ZIP="$HOME/.cache/linphone-sdk-$V.zip"
mkdir -p "$HOME/.cache" Vendor
if [ ! -s "$ZIP" ]; then
  for i in 1 2 3; do
    curl -fsS -m 900 -o "$ZIP.part" "https://download.linphone.org/releases/ios/linphone-sdk-$V.zip" && mv "$ZIP.part" "$ZIP" && break
    sleep 10
  done
fi
[ -s "$ZIP" ] || exit 1
rm -rf Vendor/XCFrameworks Vendor/LinphoneWrapper.swift Vendor/_x
mkdir Vendor/_x
unzip -q "$ZIP" 'linphone-sdk/apple-darwin/XCFrameworks/*' 'linphone-sdk/apple-darwin/share/linphonesw/LinphoneWrapper.swift' -d Vendor/_x
mv Vendor/_x/linphone-sdk/apple-darwin/XCFrameworks Vendor/XCFrameworks
mv Vendor/_x/linphone-sdk/apple-darwin/share/linphonesw/LinphoneWrapper.swift Vendor/LinphoneWrapper.swift
rm -rf Vendor/_x
ls Vendor/XCFrameworks
