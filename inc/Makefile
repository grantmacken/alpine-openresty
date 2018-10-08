include ../.env

.PHONY: pack
pack:
	@echo $(OR_VER)
	@cd ../ && docker build \
  --target=pack \
  --tag=$(DOCKER_IMAGE):pack \
 .

.PHONY: base
base:
	@echo $(OR_VER)
	@cd ../ && docker build \
  --target=base \
  --tag=$(DOCKER_IMAGE):base \
 .

.PHONY: dev
dev:
	@echo $(OR_VER)
	@cd ../ && docker build \
  --target="dev" \
  --tag="$(DOCKER_IMAGE):dev" \
 .

.PHONY: push
push:
	@docker push $(DOCKER_IMAGE):pack
	@docker push $(DOCKER_IMAGE):base
	@docker push $(DOCKER_IMAGE):dev


