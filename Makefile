STYLUA     ?= stylua
LUACHECK   ?= luacheck
PRETTIER   ?= prettier
NVIM       ?= nvim

ROOT := $(CURDIR)

AUTOGEN := scripts/autogen.lua
MANIFEST := assets/manifest.lua

DEFAULTS := lua/core/profile/defaults.lua
TYPES := lua/core/profile/types.lua

LUA_FILES := $(shell git ls-files '*.lua')
MARKDOWN_FILES := $(shell git ls-files '*.md')
YAML_FILES := $(shell git ls-files '*.yml' '*.yaml')

GENERATED := $(DEFAULTS) $(TYPES)

$(GENERATED) &: $(AUTOGEN) $(MANIFEST)
	$(AUTOGEN) --target 'none,+runtime,+readme' -v

autogen: $(GENERATED)

format:
	$(STYLUA) $(LUA_FILES)
	$(PRETTIER) --write $(YAML_FILES) $(MARKDOWN_FILES)

lint:
	$(LUACHECK) $(LUA_FILES)

check: autogen format lint
	git diff --exit-code

.PHONY: check format lint autogen
