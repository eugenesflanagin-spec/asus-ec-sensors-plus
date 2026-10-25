# SPDX-License-Identifier: GPL-2.0-only
#
# Build the module against a kernel's build tree.
#   make                      -> for the running kernel
#   make KVER=6.x.y-arch1-1   -> for another installed kernel
#   make KDIR=/path/to/build  -> for any kernel build tree
#
# If the kernel was built with clang (CONFIG_CC_IS_CLANG=y, e.g. linux-tkg
# "llvm" or CachyOS kernels), the module must be built with clang too, so
# LLVM=1 is added automatically.

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

LLVM_FLAG := $(if $(shell grep -s '^CONFIG_CC_IS_CLANG=y' $(KDIR)/.config),LLVM=1,)

.PHONY: all modules clean
all: modules

modules:
	$(MAKE) -C $(KDIR) M=$(CURDIR) $(LLVM_FLAG) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) $(LLVM_FLAG) clean
