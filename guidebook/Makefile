serve:
	mdbook serve --open

docker-build:
	docker build . -t spyderbat-eval-guidebook

update-image: docker-build
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/a6j2k0g1
	docker tag spyderbat-eval-guidebook:latest public.ecr.aws/a6j2k0g1/spyderbat-eval-guidebook:latest
	docker push public.ecr.aws/a6j2k0g1/spyderbat-eval-guidebook:latest

