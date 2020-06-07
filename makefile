.PHONY: default build clean build_folder run

default: build

build: build/os.iso

build_folder:
	mkdir -p build

build/os.iso: build/kernel.bin grub.cfg
	mkdir -p build/isofiles/boot/grub
	cp grub.cfg build/isofiles/boot/grub
	cp build/kernel.bin build/isofiles/boot/
	grub-mkrescue -o $@ build/isofiles

build/multiboot_header.o: multiboot_header.asm build_folder
	nasm -f elf64 $< -o $@

build/boot.o: boot.asm build_folder
	nasm -f elf64 $< -o $@

build/kernel.bin: linker.ld build/multiboot_header.o build/boot.o
	ld -n -o $@ -T $^

run: build/os.iso
	qemu-system-x86_64 -cdrom build/os.iso

clean:
	rm -rf build
