#!/bin/bash
set -eo pipefail

BPID="$1"
BPVER="$2"
WORK="./buildpacks"

if [ -z "$BPID" ] || [ -z "$BPVER" ]; then
	echo ""
	echo "USAGE:"
	echo "  clone.sh <buildpack-id> <buildpack-version>"
	echo ""
	echo "Enter the buildpack id/version for a composite buildpack."
	echo "The script will clone the composite and all component buildpacks."
	echo ""
	exit 255
fi

if [ -z "$WORK" ]; then
	echo "WORK cannot be empty"
	exit 254
fi

mkdir -p "$WORK"
rm -rf "${WORK:?}/"*

git clone "https://github.com/$BPID" "$WORK/$BPID"
pushd "$WORK/$BPID" >/dev/null
git -c "advice.detachedHead=false" checkout "v$BPVER"
popd >/dev/null

for GROUP in $(yj -t < "$WORK/$BPID/buildpack.toml" | jq -rc '.order[].group[]'); do
	export BUILDPACK=$(echo "$GROUP" | jq -r ".id")
	export VERSION=$(echo "$GROUP" | jq -r ".version")
	export CNB_DIRECTORY="$(echo "$BUILDPACK" | tr '/' '_')/${VERSION}"
	if [[ -d "${WORK}/${CNB_DIRECTORY}" ]]; then continue; fi
	mkdir -p "${WORK}/${CNB_DIRECTORY}"
	git clone "https://github.com/$BUILDPACK" "${WORK}/${CNB_DIRECTORY}"
	pushd "${WORK}/${CNB_DIRECTORY}" >/dev/null
	git -c "advice.detachedHead=false" checkout "v$VERSION"
	popd >/dev/null
done
