# Compiler and flags
CC = cc
CFLAGS = -g
CPPFLAGS = -I. -Iglibs
LDFLAGS = -lglfw -lm

# Targets
TARGET = build/demo
CBMCHARGEN = build/cbmchargen

# Source files for each target
GLAD_SOURCES = libs/glad/glad.c
COMMON_GLIB_SOURCES = libs/common.c
CBMCHARGEN_SOURCES = cbmcharmode.c
DEMO_SOURCES = $(GLAD_SOURCES) $(COMMON_GLIB_SOURCES) $(CBMCHARGEN_SOURCES) main.c 

# Object files for each target
DEMO_OBJS = $(DEMO_SOURCES:.c=.o)
COMMON_GLIB_OBJS = $(COMMON_GLIB_SOURCES:.c=.o)
CBMCHARGEN_OBJS = $(CBMCHARGEN_SOURCES:.c=.o)


# Default target
all: $(TARGET)

# Link the Demo executable
$(TARGET): $(DEMO_OBJS)
	@mkdir -p build
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

# Compile C source files to object files
%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

# Clean build artifacts
clean:
	rm -f $(DEMO_OBJS) $(CBMCHARGEN_OBJS) $(TARGET) $(CBMCHARGEN)
	rm -rf build

# Test target
test: $(CBMCHARGEN)

# Phony targets
.PHONY: all clean test