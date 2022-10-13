#!/bin/bash

# Things in parentheses are executed in a subshell
(cd bootloader ; mkdir -p bin ; nasm -o bin/boot bootloader.asm)
boot_result=$? # $? is the result of the last command

(make -C kernel) # -C tells make to make the provided directory
make_result=$?

echo "Make result: $make_result"

if [ "$boot_result" = "0" ] && [ "$make_result" = "0" ]
then
    cp bootloader/boot ./os.img
    cat kernel/bin/kernel >> os.img

    fsize=$(wc -c < os.img)
    sectors=$(( $fsize / 512 ))

    echo "Build finished successfully"
    echo "ALERT: Adjust boot sector to load $sectors sectors"
else
    result=`expr $boot_result + $make_result`
    echo "Build failed with error code $result. See output for more info."
fi

qemu-system-x86_64.exe -drive format=raw,file=os.img