#!/bin/bash

set -e

if [ $# -eq 0 ] ; then
	echo "Usage: ./update.sh <docker/notary tag or branch>"
	exit
fi

VERSION=$1

# cd to the current directory so the script can be run from anywhere.
cd `dirname $0`

echo "Fetching and building notary $VERSION..."

# Create a temporary directory.
TEMP=`mktemp -d /$TMPDIR/notary.XXXXXX`

git clone -b $VERSION https://github.com/docker/notary.git "$TEMP"
docker build -f "$TEMP/notary-signer-Dockerfile" -t notary-signer-builder "$TEMP"

# Create a dummy notary-build container so we can run a cp against it.
ID=$(docker create notary-signer-builder)

# Update the local binary and config file.
docker cp $ID:/go/bin/notary-signer notary-signer
docker cp $ID:/go/src/github.com/docker/notary/cmd/notary-signer/config.json notary-signer
docker cp $ID:/go/src/github.com/docker/notary/fixtures notary-signer
docker cp $ID:/go/src/github.com/docker/notary/signer/softhsm2.conf notary-signer

# Cleanup.
docker rm -f $ID
docker rmi notary-signer-builder

echo "Done."
