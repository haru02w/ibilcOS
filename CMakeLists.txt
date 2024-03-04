cmake_minimum_required(VERSION 3.5)
project(ibilcOS CXX)
enable_language(ASM_NASM)

set(CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_COMPILER clang++)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # set clang-format flags
set(CMAKE_TRY_COMPILE_TARGET_TYPE "STATIC_LIBRARY")
set(CMAKE_VERBOSE_MAKEFILE true)
set(TARGET_ARCH x86_64)

set (CXX_WARNING_LEVELS -Wall -Wextra -Wpedantic)
set (INTERNAL_CXX_FLAGS -g -O2 -ffreestanding -nostdlib -mcmodel=kernel -fno-exceptions -fno-rtti)
set (XORRISO_FLAGS -as mkisofs -b limine-bios-cd.bin -no-emul-boot -boot-load-size 4 -boot-info-table --efi-boot limine-uefi-cd.bin --efi-boot-part --efi-boot-image --protective-msdos-label)
set (QEMU_FLAGS -M q35,smm=off -net none -smp 4 -d int,guest_errors -d cpu_reset -m 2G -no-shutdown -no-reboot -debugcon file:debug.log -D ./qemu.log -device isa-debug-exit)
list (APPEND QEMU_FLAGS -monitor stdio -enable-kvm -cpu host)
set (LINKER_FILE ${CMAKE_SOURCE_DIR}/kernel/linker.${TARGET_ARCH}.ld)

if (${TARGET_ARCH} STREQUAL x86_64)
    list (APPEND INTERNAL_CXX_FLAGS -m64 -target x86_64-none)
    add_definitions (-DPH_ARCH=PH_ARCH_X86_64)
elseif ($(TARGET_ARCH) STREQUAL ia32)
    list (APPEND INTERNAL_CXX_FLAGS -m32 -target i386-none)
    add_definitions (-DPH_ARCH=PH_ARCH_IA32)
endif ()

file (GLOB_RECURSE SOURCES "kernel/*.cpp" "kernel/*/*.cpp")

set (BUILD_DIR ${CMAKE_SOURCE_DIR}/build)
set (ISO_ROOT ${BUILD_DIR}/iso_root)
set (CMAKE_RUNTIME_OUTPUT_DIRECTORY ${ISO_ROOT})
set (CMAKE_EXECUTABLE_SUFFIX .elf)
file(MAKE_DIRECTORY ${ISO_ROOT})

add_executable (${PROJECT_NAME} ${SOURCES})

target_compile_options (${PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:CXX>: ${INTERNAL_CXX_FLAGS} ${CXX_WARNING_LEVELS} -fno-stack-protector -MMD -fno-pic -fno-pie -fno-lto -fno-stack-check -mno-red-zone -mno-sse -mno-sse2 -mno-mmx -mno-80387>)
target_link_options (${PROJECT_NAME} PUBLIC -g -nostdlib -no-pie -static -z max-page-size=0x1000 -T ${LINKER_FILE})
target_include_directories (${PROJECT_NAME} PRIVATE kernel boot/limine)

add_custom_target (setup
    COMMAND make -C ${CMAKE_SOURCE_DIR}/boot/limine
    COMMAND cp -v ${CMAKE_SOURCE_DIR}/limine.cfg ${CMAKE_SOURCE_DIR}/boot/limine/{limine-bios.sys,limine-bios-cd.bin,limine-uefi-cd.bin} ${ISO_ROOT})

add_custom_command (TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND rm -rf ${ISO_ROOT}/${PROJECT_NAME}.iso
    COMMAND cp -v ${CMAKE_SOURCE_DIR}/limine.cfg ${ISO_ROOT}
    COMMAND xorriso ${XORRISO_FLAGS} ${ISO_ROOT} -o ${BUILD_DIR}/${PROJECT_NAME}.iso
    COMMAND ${CMAKE_SOURCE_DIR}/boot/limine/limine bios-install ${BUILD_DIR}/${PROJECT_NAME}.iso
    DEPENDS ${BUILD_LIMINE})

add_custom_target (qemu COMMAND qemu-system-x86_64 ${QEMU_FLAGS} ${BUILD_DIR}/${PROJECT_NAME}.iso DEPENDS ${PROJECT_NAME})
add_custom_target (qemu-debug COMMAND qemu-system-x86_64 ${QEMU_FLAGS} -s -S ${BUILD_DIR}/${PROJECT_NAME}.iso DEPENDS ${PROJECT_NAME})
