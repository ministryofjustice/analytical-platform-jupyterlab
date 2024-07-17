IMAGE_NAME = ghcr.io/ministryofjustice/analytical-platform-jupyterlab:latest

test: build
	container-structure-test test --platform linux/amd64 --config test/container-structure-test.yml --image $(IMAGE_NAME)

run: build
	docker run -it --rm --publish 8080:8080 ghcr.io/ministryofjustice/analytical-platform-jupyterlab:latest

build:
	@ARCH=`uname -m`; \
	case $$ARCH in \
	aarch64 | arm64) \
		echo "Building on $$ARCH architecture"; \
		docker build --platform linux/amd64 --file Dockerfile --tag $(IMAGE_NAME) . ;; \
	*) \
		echo "Building on $$ARCH architecture"; \
		docker build --file Dockerfile --tag $(IMAGE_NAME) . ;; \
	esac
