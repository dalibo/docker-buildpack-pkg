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
    export GPG_TTY=
    gpg --batch --import <<<"$GPG_PRIVATE_KEY"
    uid="$(gpg --with-colons --list-keys | grep --max-count=1 --only-matching --perl-regexp '^uid:.+[0-9A-Z]::\K([^:]+)')"

    if [ -v GPG_PASSPHRASE ] ; then
        echo "allow-preset-passphrase" >> ~/.gnupg/gpg-agent.conf
        gpg-connect-agent reloadagent /bye
        grip="$(gpg --with-colons --with-keygrip --list-keys | grep --max-count=1 --only-matching  --perl-regexp '^grp:+\K[^:]+')"
        # Avoid leaking secret by sending through stdin.
        xargs -I% /usr/libexec/gpg-preset-passphrase --passphrase % --preset "$grip" <<<"$GPG_PASSPHRASE"
    fi

    rpm --addsign --define "_gpg_name $uid" "${rpms[@]}"

    # test signature
    gpg --armor --export "$uid" > /etc/pki/rpm-gpg/RPM-GPG-KEY-RPMBUILD
    rpm --checksig "${rpms[@]}"
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
