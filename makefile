BUILD_FLAGS		= -O0 -g -std=c++11 -Wall $(shell MagickWand-config --cflags)
BUILD_PATH		= ~/.chunkwm_plugins
SRC				= ./plugin.mm ./blurwallpaper.c
BINS			= $(BUILD_PATH)/blur.so
LINK			= -shared -fPIC -framework Carbon -framework Cocoa -framework ApplicationServices -framework Foundation -fmodules -fcxx-modules -mmacosx-version-min=10.6 -lsqlite3 $(shell MagickWand-config --libs) `pkg-config --cflags --libs MagickWand`

all: $(BINS)

install: BUILD_FLAGS=-O2 -std=c++11 -Wall
install: clean $(BINS)

.PHONY: all clean install

$(BUILD_PATH):
	mkdir -p $(BUILD_PATH)

clean:
	rm -f $(BUILD_PATH)/blur.so

$(BUILD_PATH)/blur.so: $(SRC) | $(BUILD_PATH)
	clang++ $^ $(BUILD_FLAGS) -o $@ $(LINK)

