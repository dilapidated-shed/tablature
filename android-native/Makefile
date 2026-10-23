# C is confined to the explicitly authorized Android/Lua ABI boundary.
# The checked Idriç payload is built separately; this target cannot fabricate it.
ROOT := $(abspath ..)
NDK ?=
SYSROOT ?= $(NDK)/toolchains/llvm/prebuilt/linux-x86_64/sysroot
CLANG := $(NDK)/toolchains/llvm/prebuilt/linux-x86_64/bin/clang
LUA_SOURCE ?=
TARGET ?= aarch64-linux-android21
ABI ?= arm64-v8a
OUTPUT ?= $(ROOT)/build/android/$(ABI)/libchordreader.so
LUA_FILES := $(filter-out $(addprefix $(LUA_SOURCE)/,lua.c luac.c linit.c liolib.c loslib.c ldblib.c),$(wildcard $(LUA_SOURCE)/*.c))
APP_FILES := platform.c lua-runtime.c

.PHONY: native
native: $(OUTPUT)

$(OUTPUT): $(APP_FILES) platform.h lua-platform.h $(LUA_FILES)
	@test -x "$(CLANG)" && test -f "$(LUA_SOURCE)/lua.h"
	mkdir -p "$(@D)"
	$(CLANG) --target=$(TARGET) --sysroot="$(SYSROOT)" -std=c11 -O2 \
		-fPIC -shared -D_GNU_SOURCE -DLUA_USE_LINUX -I"$(LUA_SOURCE)" -include lua-platform.h \
		-Wl,--no-undefined -Wl,-z,max-page-size=16384 \
		$(APP_FILES) $(LUA_FILES) -landroid -llog -ldl -lm -o "$@"
