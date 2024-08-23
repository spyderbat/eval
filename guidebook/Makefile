VERSION := $(shell git describe --tags)

serve:
	mdbook serve --open

docker-build:
	docker buildx build . -t spyderbat-eval-guidebook

update-image:
	git describe --tags
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/a6j2k0g1
	docker buildx build --platform=linux/amd64 --push -t public.ecr.aws/a6j2k0g1/spyderbat-eval-guidebook:${VERSION} -t public.ecr.aws/a6j2k0g1/spyderbat-eval-guidebook:latest .

