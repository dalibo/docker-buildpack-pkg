all: alpine centos7 centos6 bookworm bullseye buster rockylinux9 rockylinux8 stretch jessie noble jammy

.PHONY: centos6
alpine centos7 centos6 trixie bookworm bullseye buster rockylinux9 rockylinux8 stretch jessie noble jammy:
	docker build --pull \
	  --build-arg http_proxy \
	  --tag dalibo/buildpack-pkg:$@ \
	  --file Dockerfile.$@ \
	.

push-%:
	docker push dalibo/buildpack-pkg:$*
