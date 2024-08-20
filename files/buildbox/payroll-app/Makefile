all: build push-container

build:
	docker buildx build --load --platform=linux/amd64 -t payroll-calculator:latest .

push-container:
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws/xxxxxxxx
	docker tag payroll-calculator:latest public.ecr.aws/xxxxxxxx/payroll-calculator:latest
	docker push public.ecr.aws/xxxxxxxx/payroll-calculator:latest

