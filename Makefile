NVIM_CONFIG ?= $(PWD)

# Find all lua files
LUA_FILES := $(shell fd -e lua . $(NVIM_CONFIG))

# Tools
STYLUA ?= stylua
LUACHECK ?= luacheck

.PHONY: all format lint check

all: format lint

# Format all lua files with stylua
format:
	@echo "Formatting Lua files in $(NVIM_CONFIG)..."
	@$(STYLUA) $(LUA_FILES)

# Lint all lua files with luacheck
lint:
	@echo "Linting Lua files in $(NVIM_CONFIG)..."
	@$(LUACHECK) $(LUA_FILES)

# Just check formatting (CI friendly)
check:
	@echo "Checking formatting..."
	@$(STYLUA) --check $(LUA_FILES)
	@echo "Running luacheck..."
	@$(LUACHECK) $(LUA_FILES)
