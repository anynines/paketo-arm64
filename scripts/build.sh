#!/bin/bash
set -eo pipefail

BPID="$1"
WORK="./buildpacks"

if [ -z "$BPID" ]; then
	echo ""
	echo "USAGE:"
	echo "  build.sh <buildpack-id>"
	echo ""
	echo "Enter the buildpack id for a composite buildpack."
	echo "The script will build the composite and all component buildpacks."
	echo "This requires a directory setup in advance, like what you get from running 'clone.sh'."
	echo ""
	exit 255
fi

if [ -z "$WORK" ] && ! [ -d "$WORK" ]; then
	echo "WORK cannot be empty and must exist"
	exit 254
fi

for GROUP in $(yj -t < "$WORK/$BPID/buildpack.toml" | jq -rc '.order[].group[]'); do
	export BUILDPACK=$(echo "$GROUP" | jq -r ".id")
	export VERSION=$(echo "$GROUP" | jq -r ".version")
	export SYMLINK=$(echo "$BUILDPACK-arm64" | tr '/' '_')
	pushd "$WORK/$BUILDPACK" >/dev/null
		create-package --destination ./out --version "$VERSION"
		pushd ./out >/dev/null
			yj -ty < buildpack.toml | yq '.buildpack.version = env(VERSION)' | yj -yt > buildpack.toml.temp
			mv buildpack.toml.temp buildpack.toml
			pack buildpack package "$BUILDPACK-arm64:$VERSION"
		popd >/dev/null
	popd >/dev/null
	pushd "$WORK" >/dev/null
	popd >/dev/null
done
