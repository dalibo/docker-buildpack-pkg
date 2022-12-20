all: alpine centos7 centos6 bookworm bullseye buster rockylinux9 rockylinux8 stretch jessie

.PHONY: centos6
alpine centos7 centos6 bookworm bullseye buster rockylinux9 rockylinux8 stretch jessie:
	docker build --pull \
	  --build-arg http_proxy \
	  --tag dalibo/buildpack-pkg:$@ \
	  --file Dockerfile.$@ \
	.

push-%:
	docker push dalibo/buildpack-pkg:$*
