#!/bin/bash
#
# Generic script to build a RPM from spec and sources.
#
# Usage: rpmbuild.sh SPEC [SOURCE ...]
#
# Runs rpmbuild as testuser.

set -eux

BUILDDIR="${BUILDDIR-_build}"
SPEC="$1"; shift
SOURCES=("$@")
specname="${SPEC##*/}"
basespec="${specname%.spec}"

# TOOLS

retry yum-builddep -y "$SPEC"

# SOURCES

topdir=~testuser/rpmbuild
mkdir -p "$topdir/SOURCES" "$topdir/SPECS"
cp -vf "$SPEC" "$topdir/SPECS/"
cp -rvf "${SOURCES[@]}" "$topdir/SOURCES/"
# rpmbuild exige la propriété des fichiers.
chown -R testuser "$topdir"

# BUILD

sudo -u testuser rpmbuild \
    --clean \
    --define "_topdir $topdir" \
    -bb "$SPEC"
rpms=( "$topdir"/RPMS/*/*.rpm )

# SIGN

if [ -v GPG_PRIVATE_KEY ] ; then
    gpg --batch --import <<<"$GPG_PRIVATE_KEY"
    uid="$(gpg --with-colons --list-keys | grep --max-count=1 --only-matching --perl-regexp '^uid:.+[0-9A-Z]::\K([^:]+)')"
    rpm --delsign "${rpms[@]}"
    rpm --define '__gpg /usr/bin/gpg2 --batch' --addsign --define "_gpg_name $uid" "${rpms[@]}"
fi

# VERIFY

retry yum install -y "${rpms[@]}"
for rpm in "${rpms[@]}" ; do
    rpm -vv --verify -p "${rpm}"
done

# EXPORT

ownership="$(stat -c %u:%g "$SPEC")"
destdir="$(rpm --eval "$BUILDDIR/rhel%{rhel}/$basespec/")"
mkdir -p "$destdir"
chown -v "$ownership" "${destdir%/*/*}" "${destdir%/*}"
cp -avf "${rpms[@]}" "$destdir"
chown -Rv "$ownership" "$destdir"
find "$destdir" -type f -printf "%P\n"
