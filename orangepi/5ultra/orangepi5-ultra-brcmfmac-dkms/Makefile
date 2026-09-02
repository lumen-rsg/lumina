KERNELRELEASE ?= $(shell uname -r)
KERNEL_SOURCE ?= /lib/modules/$(KERNELRELEASE)/build

.PHONY: all clean

all:
	$(MAKE) -f $(KERNEL_SOURCE)/Makefile \
		M=$(CURDIR)/brcmfmac MO=$(CURDIR)/output modules

clean:
	$(MAKE) -f $(KERNEL_SOURCE)/Makefile \
		M=$(CURDIR)/brcmfmac MO=$(CURDIR)/output clean
