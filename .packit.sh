#!/usr/bin/env bash

# This script handles any custom processing of the spec file using the `fix-spec-file`
# action in .packit.yaml.

set -eox pipefail

PACKAGE=podman

# Set path to rpm spec file
SPEC_FILE=rpm/$PACKAGE.spec

# Get short sha
SHORT_SHA=$(git rev-parse --short HEAD)

# Get Version from HEAD
VERSION=$(grep '^const RawVersion' version/rawversion/version.go | cut -d\" -f2)

# RPM Version can't take "-"
RPM_VERSION=$(echo $VERSION | sed -e 's/-/~/')

# Generate source tarball from HEAD
git-archive-all -C $(git rev-parse --show-toplevel) --prefix=$PACKAGE-$VERSION/ rpm/$PACKAGE-$VERSION.tar.gz

# RPM Spec modifications

# Use the Version from HEAD in rpm spec
sed -i "s/^Version:.*/Version: $RPM_VERSION/" $SPEC_FILE

# Use Packit's supplied variable in the Release field in rpm spec.
sed -i "s/^Release:.*/Release: $PACKIT_RPMSPEC_RELEASE%{?dist}/" $SPEC_FILE

# Ensure last part of the release string is the git shortcommit without a
# prepended "g"
sed -i "/^Release: $PACKIT_RPMSPEC_RELEASE%{?dist}/ s/\(.*\)g/\1/" $SPEC_FILE

# Use above generated tarball as Source in rpm spec
sed -i "s/^Source0:.*.tar.gz/Source0: $PACKAGE-$VERSION.tar.gz/" $SPEC_FILE

# Update setup macro to use the correct build dir
sed -i "s/^%autosetup.*/%autosetup -Sgit -n %{name}-$VERSION/" $SPEC_FILE

# podman --version should show short sha
sed -i "s/^const RawVersion = \"$VERSION\"/const RawVersion = \"$VERSION-$SHORT_SHA\"/" version/rawversion/version.go

# use ParseTolerant to allow short sha in version
sed -i "s/^var Version.*/var Version, err = semver.ParseTolerant(rawversion.RawVersion)/" version/version.go