CHS_ROOT        ?= $(shell pwd)/cheshire
CC              ?= gcc
OBJDUMP         ?= objdump
RV_CC           ?= riscv64-unknown-elf-gcc
RV_OBJDUMP      ?= riscv64-unknown-elf-objdump

# Common to all targets and architectures
COMMON_FLAGS    := -Wall -Wextra -O2 -ffunction-sections -fdata-sections -fuse-linker-plugin -flto
CFLAGS          := $(COMMON_FLAGS) -ggdb
LDFLAGS         := $(COMMON_FLAGS) -Wl,--gc-sections -Wl,-flto

# Specific flags for the RISC-V 64 targets
RV_FLAGS        := -march=rv64gc_zifencei -mabi=lp64d -mstrict-align
RV_CFLAGS       := $(CFLAGS) $(RV_FLAGS) -mcmodel=medany -mexplicit-relocs -fverbose-asm -pipe -static
RV_LDFLAGS      := $(LDFLAGS) $(RV_FLAGS)

# Specific flags for the RISC-V 64 bare-metal targets (additionally to the RV_* flags)
CHS_FLAGS       := -D__CHESHIRE__
CHS_CFLAGS      := $(RV_CFLAGS) $(CHS_FLAGS) -fno-builtin -I$(CHS_ROOT)/sw/include -I$(CHS_ROOT)/sw/deps/printf
CHS_LDFLAGS     := $(RV_LDFLAGS) $(CHS_FLAGS) -nostartfiles -Wl,-L$(CHS_ROOT)/sw/link -Wl,-T$(CHS_ROOT)/sw/link/dram.ld

.PHONY: all clean

all: bandwidth-rv64 bandwidth-rv64-chs

%.o: %.c
	@$(CC) $(CFLAGS) -c -o $@ $<
	@echo "(CC) $@"

%-rv64.o: %.c
	@$(RV_CC) $(RV_CFLAGS) -c -o $@ $<
	@echo "(CC) $@"

%-rv64.o: %-rv64.S
	@$(RV_CC) $(RV_CFLAGS) -c -o $@ $<
	@echo "(AS) $@"

%-rv64-bare.o: %.c
	@$(RV_CC) $(CHS_CFLAGS) -c -o $@ $<
	@echo "(CC) $@"

%-rv64-bare.o: %-rv64.S
	@$(RV_CC) $(CHS_CFLAGS) -c -o $@ $<
	@echo "(AS) $@"

bandwidth: bandwidth.o
	@nasm -f elf64 mem-routines-x86_64.S -o mem-routines-x86_64.o
	@echo "(AS) mem-routines-x86_64.o"
	@$(CC) $(LDFLAGS) -o $@ mem-routines-x86_64.o $<
	@echo "(LD) $@"
	@$(OBJDUMP) -d $@ > $@.dump
	@echo "(DUMP) $@.dump"

bandwidth-rv64: mem-routines-rv64.o bandwidth-rv64.o
	@$(RV_CC) $(RV_LDFLAGS) $^ -o $@
	@echo "(LD) $@"
	@$(RV_OBJDUMP) -d $@ > $@.dump
	@echo "(DUMP) $@.dump"

$(CHS_ROOT)/sw/lib/libcheshire.a:
	@$(MAKE) -C $(CHS_ROOT) $(CHS_ROOT)/sw/lib/libcheshire.a

bandwidth-rv64-chs: mem-routines-rv64-bare.o bandwidth-rv64-bare.o $(CHS_ROOT)/sw/lib/libcheshire.a
	@$(RV_CC) $(CHS_LDFLAGS) -o $@ $^
	@echo "(LD) $@"
	@$(RV_OBJDUMP) -d $@ > $@.dump
	@echo "(DUMP) $@.dump"

clean:
	@rm -f *.o *.dump bandwidth bandwidth-rv64 bandwidth-rv64-chs

