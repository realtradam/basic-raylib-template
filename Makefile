# based on https://makefiletutorial.com/#makefile-cookbook
TARGET_EXEC := game

BUILD_DIR := ./build
EXTERNAL_DIR := ./external
SRC_DIRS := ./src 

EXTERNAL_INC_DIRS := $(addprefix $(EXTERNAL_DIR)/, raygui/src raygui/styles raylib/src STC/include)

WFLAGS := -m64 -std=c99 -Wall -Wextra -Wshadow -Wcast-qual -Wstrict-prototypes -Wmissing-prototypes -Wfloat-equal -Wformat=2 -Werror \
		  -Wno-error=unused-variable -Wno-error=missing-prototypes -Wno-error=float-equal -Wno-error=unused-parameter -Wno-error=cast-qual -Wno-error=shadow

# Find all the C and C++ files we want to compile
# Note the single quotes around the * expressions. The shell will incorrectly expand these otherwise, but we want to send the * directly to the find command.
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c' -or -name '*.s')

# Prepends BUILD_DIR and appends .o to every src file
# As an example, ./your_dir/hello.cpp turns into ./build/./your_dir/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (suffix version without %).
# As an example, ./build/hello.cpp.o turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)

# Every folder in ./src will need to be passed to GCC so that it can find header files
INC_DIRS := $(shell find $(SRC_DIRS) -type d) 
# Add a prefix to INC_DIRS. So moduleA would become -ImoduleA. GCC understands this -I flag
INC_FLAGS := $(addprefix -I,$(INC_DIRS) $(EXTERNAL_INC_DIRS))

# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d instead of .o as the output.
CPPFLAGS := $(INC_FLAGS) -MMD -MP


# -Xlinker -rpath tells executable where to look for shared libraries at runtime
LDFLAGS := $(addprefix -L,$(EXTERNAL_INC_DIRS)) $(addprefix -Xlinker -rpath=,$(EXTERNAL_INC_DIRS)) -lraylib -lm -lpthread -ldl -lrt -lX11

# Note: might need to change CC to CXX once we have a C++ lib
# The final build step.
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS) raylib
	$(CC) $(OBJS) -o $@ $(LDFLAGS)

# Build step for C source
$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(WFLAGS) -g -c $< -o $@

.PHONY: play
play: $(BUILD_DIR)/$(TARGET_EXEC)
	./$(BUILD_DIR)/$(TARGET_EXEC)

.PHONY: raylib
raylib: $(EXTERNAL_DIR)/raylib/src/libraylib.so

$(EXTERNAL_DIR)/raylib/src/libraylib.so:
	$(MAKE) -C $(EXTERNAL_DIR)/raylib/src RAYLIB_LIBTYPE=SHARED

.PHONY: bear
bear: clean
	bear -- make

.PHONY: clean
clean:
	rm -r $(BUILD_DIR) || true # always succeed even if no such file

.PHONY: deepclean
deepclean: clean
	$(MAKE) -C external/dev/raylib/src clean

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Makefiles. Initially, all the .d files will be missing, and we don't want those
# errors to show up.
-include $(DEPS)
