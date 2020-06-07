boot_src:=src/boot

.PHONY: default target clean target_folder run

default: target

target: target/os.iso

target_folder:
	mkdir -p target

target/os.iso: target/kernel.bin $(boot_src)/grub.cfg
	mkdir -p target/isofiles/boot/grub
	cp $(boot_src)/grub.cfg target/isofiles/boot/grub
	cp target/kernel.bin target/isofiles/boot/
	grub-mkrescue -o $@ target/isofiles

target/multiboot_header.o: $(boot_src)/multiboot_header.asm target_folder
	nasm -f elf64 $< -o $@

target/boot.o: $(boot_src)/boot.asm target_folder
	nasm -f elf64 $< -o $@

target/kernel.bin: $(boot_src)/linker.ld target/multiboot_header.o target/boot.o
	ld -n -o $@ -T $^

run: target/os.iso
	qemu-system-x86_64 -cdrom target/os.iso

clean:
	cargo clean
