# [dalibo/buildpack-pkg](https://hub.docker.com/r/dalibo/buildpack-pkg)

Packaging utils for building PostgreSQL tool packages.

This image is built from
[dalibo/buildpack](https://hub.dalibo.com/r/dalibo/buildpack).

RHEL entrypoint accepts SPEC and Source files as parameters.
Outputs all RPMS in `_build/rhel<RHEL>/<specname>/`.

## Tools

- nfpm
- Python and pip.
- uv
- rpmbuild

## Tags

- `trixie`.
- `bookworm`.
- `bullseye`.
- `jammy`.
- `noble`.
- `rockylinux10`.
- `rockylinux9`.
- `rockylinux8`.
