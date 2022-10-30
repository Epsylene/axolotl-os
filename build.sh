#!/bin/bash

rm -f os.img

(cd bootloader ; nasm -o boot bootloader.asm)
boot_result=$?

(make -C kernel)
make_result=$?

echo Make Result: $make_result

if [ "$boot_result" = "0" ] && [ "$make_result" = "0" ]
then
    cp bootloader/boot ./os.img
    cat kernel/kernel >> os.img

    fsize=$(wc -c < os.img)
    sectors=$(( $fsize / 512 ))

    echo "Build finished successfully"
    echo "Adjust boot sector to load $sectors sectors"

    (make -C kernel clean)

    qemu-system-x86_64.exe -drive format=raw,file=os.img
else
    result=`expr $boot_result + $make_result`
    echo "Build failed with error code $result. See output for more info."
fi