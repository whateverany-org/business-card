ifndef MAIN_MK_INCLUDED
MAIN_MK_INCLUDED := 1

HOST_BASE_DIR      := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
OCI_WORKING_DIR    := /a
MAIN_BASE_DIR      := $(shell grep -q -x '0::/' /proc/self/cgroup && echo "$(OCI_WORKING_DIR)" || echo "$(HOST_BASE_DIR)")

.ONESHELL:
SHELL := /bin/bash
.SHELLFLAGS: -x

ENV_FILE           ?= $(MAIN_BASE_DIR)/.env
ENV_TEMPLATE_FILE  ?= $(ENV_FILE).template
-include $(ENV_FILE)
.EXPORT_ALL_VARIABLES:

COMMON_DIR         ?= $(MAIN_BASE_DIR)/common
COMMON_SCRIPTS_DIR ?= $(COMMON_DIR)/scripts
COMMON_MAKE_SH     ?= $(COMMON_SCRIPTS_DIR)/make.sh

OCI                ?= podman
OCI_ENV_VARS       ?= $(shell grep -v '^#' $(ENV_FILE) | sed -e 's/^\(^[^=]*\)=.*/\1/' | tr '\n' ' ')
OCI_ENV_ARGS       ?= $(foreach _s,$(OCI_ENV_VARS),--secret $(_s),type=env) $(foreach _s,$(OCI_ENV_VARS),--secret TF_VAR_$(_s),type=env)
OCI_ENV_DEPS       ?= $(foreach _t,$(OCI_ENV_VARS),_env-$(_t))

OCI_ARGS           ?= --rm --cgroup-manager=cgroupfs
OCI_COMPOSE        ?= $(OCI)-compose
OCI_DEPS           ?= $(ENV_FILE) $(OCI_ENV_DEPS)
OCI_DIR            ?= $(COMMON_DIR)/oci
OCI_COMPOSE_YAML   ?= $(MAIN_BASE_DIR)/$(OCI_COMPOSE).yaml
OCI_COMPOSE_ARGS   ?= --file $(OCI_COMPOSE_YAML)
OCI_BUILD_DIR      ?= $(COMMON_DIR)/oci
OCI_BUILD_DEFS     ?= $(shell yq -r '.services | keys | join(" ")' $(OCI_COMPOSE_YAML))
OCI_BUILD_TARGETS  ?= $(foreach DEF,$(OCI_BUILD_DEFS),build_$(DEF))
OCI_BUILD_VERSION  ?= 0.0.1
OCI_BUILD_ARGS     ?= $(OCI_ARGS) $(foreach _t,$(OCI_ENV_VARS),--build-arg '$(_t)=$${$(_t)}')
OCI_BUILD_ARGS_END ?= 
OCI_BUILD_IMAGE    ?=
#xOCI_BUILD_TAG      ?= localhost/oci_$(OCI_BUILD_IMAGE):latest
OCI_BUILD          ?= $(OCI_COMPOSE) $(OCI_COMPOSE_ARGS) --podman-build-args="$(OCI_BUILD_ARGS) $(OCI_BUILD_ARGS_END)" build
OCI_RUN_ARGS       ?= $(OCI_ARGS) $(OCI_ENV_ARGS)
OCI_RUN            ?= $(OCI_COMPOSE) $(OCI_COMPOSE_ARGS) --podman-run-args="$(OCI_RUN_ARGS) $${OCI_RUN_EXTRA_ARGS}" run 
OCI_SHELLS         ?= bcpy-kicad-/bin/bash bcpy-root-/bin/bash
OCI_DEVOPS         ?= $(OCI_RUN) devops

.DEFAULT_GOAL      := all
GOALS              ?= \
                      all \
                      build \
                      clean \
                      cache-clean \
                      distclean \
                      lint \
                      maintainer-clean \
                      oci-clean \
                      oci-secrets-clean \
                      pristine \
                      realclean \
                      shell \
                      tf \
                      tfinit \
                      tfplan \
                      tfapply \
                      usage
.PHONY: $(GOALS)

all: usage

build: $(OCI_BUILD_TARGETS)

clean:

cache-clean:

distclean:

lint:

maintainer-clean:

oci-clean:
	$(OCI) system prune --all --force
	$(OCI) volume prune --force
	$(OCI) rmi $(OCI_IMAGE_DEVOPS)

oci-secrets: oci-secrets-clean $(OCI_ENV_DEPS)

oci-secrets-clean:
	$(OCI) secret rm -a

pristine:

realclean:

shell: shell_bcpy-kicad-/bin/bash

pcbdraw:
	@#$(OCI_RUN) bcpy ./scripts/pcbdraw.sh plot business-card.kicad_pcb business-card-front.svg
	$(OCI_RUN) bcpy ./scripts/pcbdraw.sh plot business-card.kicad_pcb business-card-front.png
	@#$(OCI_RUN) bcpy ./scripts/pcbdraw.sh plot business-card.kicad_pcb business-card-front.svg
	#$(OCI_RUN) bcpy ./scripts/pcbdraw.sh render business-card.kicad_pcb business-card-front.svg
	#$(OCI_RUN) bcpy ./scripts/pcbdraw.sh plot --back business-card.kicad_pcb business-card-back.svg

define SHELL_DEF
shell_$(1):
	$(OCI_RUN) --user $(word 2,$(subst -, ,$(1))) --entrypoint "" $(word 1,$(subst -, ,$(1))) $(word 3,$(subst -, ,$(1)))
.PHONY: shell_$(1)
endef
$(foreach _t,$(OCI_SHELLS),$(eval $(call SHELL_DEF,$(_t))))

define BUILD_DEF
build_$(1): OCI_BUILD_TAG = localhost/whateverany/$(1):$(OCI_BUILD_VERSION)
	$(eval OCI_BUILD_TAG = localhost/whateverany/$(1):$(OCI_BUILD_VERSION))

build_$(1):
	$(eval OCI_BUILD_IMAGE := $(1))
	$(eval OCI_BUILD_ARGS_END := --tag localhost/whateverany/$(1):$(OCI_BUILD_VERSION))
	$(eval xOCI_BUILD_ARGS_END := --no-cache)
	@cd $(OCI_BUILD_DIR) && $(OCI_BUILD) "$(1)"
	@$(OCI) images --filter "reference=$(OCI_BUILD_TAG)" --format "{{.Repository}}:{{.Tag}}" | grep -q "$(OCI_BUILD_TAG)" && echo $(OCI) rmi $(OCI_BUILD_TAG)
.PHONY: build_$(1)
endef
$(foreach _i,$(OCI_BUILD_DEFS),$(eval $(call BUILD_DEF,$(_i))))

$(ENV_FILE):
	@:
#	$(info INFO: _env)
	$(if $(wildcard $(ENV_FILE)),, $(info INFO: $(ENV_FILE) doesn't exist, copying $(ENV_FILE))$(file > $(ENV_FILE), $(file < $(ENV_TEMPLATE_FILE))))
.PHONY: $(ENV_FILE)

_env-%:
	@$(OCI) secret ls --filter Name="$(*)" --format '{{.Name}}' | grep -q "$(*)" || (echo -n "$($(*))" | $(OCI) secret create "$(*)" -) && (echo -n "$($(*))" | $(OCI) secret create "TF_VAR_$(*)" -)
.PHONY: _env-%

usage:
	@:
	$(info INFO: $(MAKE) $(GOALS))

endif # MAIN_MK_INCLUDED
