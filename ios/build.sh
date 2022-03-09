#!/bin/zsh

tempdir=$(mktemp -d)
tempfile=$tempdir/archive.xcarchive

xcodebuild -quiet -project ./Gaia.xcodeproj -config Release -scheme Gaia -archivePath $tempfile archive
mv "$tempfile/Products/Applications" "$tempfile/Payload"


pushd "$tempfile/"
zip -q -r ./app.ipa ./Payload
popd

rm ./Gaia.ipa
mv "$tempfile/app.ipa" ./Gaia.ipa
