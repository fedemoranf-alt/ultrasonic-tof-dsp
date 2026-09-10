# ============================================================================
#  Host build of the DSP kernels and their unit tests.
#
#    make test      build and run the tests
#    make strict    same, but any compiler warning is a hard error
#    make sanitize  same, under AddressSanitizer + UndefinedBehaviorSanitizer
#    make clean     remove build/
#
#  `make sanitize` needs libasan/libubsan, which ship with gcc on Linux and
#  macOS but NOT with the MinGW toolchains on Windows - there it fails at the
#  link step with "cannot find -lasan". That is expected: the sanitizer pass
#  runs in CI, on Linux. Use `make test` locally on Windows.
#
#  Nothing here touches the embedded toolchains. The PSoC project is built by
#  PSoC Creator and the ESP32 firmware by PlatformIO, exactly as before.
# ============================================================================

# GNU make predefines CC = cc. That name exists on Linux and macOS but not on
# Windows with MinGW, where the compiler is only ever called gcc. Note that
# "CC ?= gcc" would NOT fix this: ?= skips variables that are already defined,
# and make's built-in default counts as defined. Testing $(origin CC) is the
# way to replace the built-in while still honouring an explicit CC=clang from
# the command line or the environment.
ifeq ($(origin CC),default)
CC := gcc
endif

CSTD     := -std=c99
OPT      := -O2
WARN     := -Wall -Wextra -pedantic
CFLAGS   := $(CSTD) $(OPT) $(WARN) $(EXTRA_CFLAGS)
LDLIBS   := -lm

BUILD    := build
SRC      := dsp.c tests/check.c tests/test_dsp.c
HDR      := dsp.h tests/check.h
BIN      := $(BUILD)/test_dsp
BIN_SAN  := $(BUILD)/test_dsp_sanitized

.PHONY: all test strict sanitize clean

all: test

test: $(BIN)
	@echo "== running unit tests =="
	@./$(BIN)

strict:
	@$(MAKE) clean
	@$(MAKE) test EXTRA_CFLAGS=-Werror

sanitize: $(BIN_SAN)
	@echo "== re-running under AddressSanitizer + UBSan =="
	@UBSAN_OPTIONS=print_stacktrace=1:halt_on_error=1 ./$(BIN_SAN)

$(BIN): $(SRC) $(HDR) | $(BUILD)
	$(CC) $(CFLAGS) -o $@ $(SRC) $(LDLIBS)

$(BIN_SAN): $(SRC) $(HDR) | $(BUILD)
	$(CC) $(CSTD) -O1 -g $(WARN) -fsanitize=address,undefined \
	    -fno-omit-frame-pointer -o $@ $(SRC) $(LDLIBS)

$(BUILD):
	@mkdir -p $(BUILD)

clean:
	@rm -rf $(BUILD)
