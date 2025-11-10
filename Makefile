all: alpine bookworm bullseye rockylinux9 rockylinux8 noble jammy

.PHONY: centos6
alpine trixie bookworm bullseye rockylinux9 rockylinux8 noble jammy:
	docker build --pull \
	  --build-arg http_proxy \
	  --tag dalibo/buildpack-pkg:$@ \
	  --file Dockerfile.$@ \
	.

push-%:
	docker push dalibo/buildpack-pkg:$*
