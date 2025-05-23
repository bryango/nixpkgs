set -o pipefail

objects=($objects)
symlinks=($symlinks)
suffices=($suffices)

mkdir root

# Needed for splash_helper, which gets run before init.
mkdir root/dev
mkdir root/sys
mkdir root/proc


for ((n = 0; n < ${#objects[*]}; n++)); do
    object=${objects[$n]}
    symlink=${symlinks[$n]}
    suffix=${suffices[$n]}
    if test "$suffix" = none; then suffix=; fi

    mkdir -p $(dirname root/$symlink)
    ln -s $object$suffix root/$symlink
done


# Get the paths in the closure of `object'.
storePaths="$(cat $closureInfo/store-paths)"


# Paths in cpio archives *must* be relative, otherwise the kernel
# won't unpack 'em.
(cd root && cp -prP --parents $storePaths .)


# Put the closure in a gzipped cpio archive.
mkdir -p $out
for PREP in $prepend; do
  cat $PREP >> $out/initrd
done
(cd root && find * .[^.*] -exec touch -h -d '@1' '{}' +)
(cd root && find * .[^.*] -print0 | sort -z | cpio --quiet -o -H newc -R +0:+0 --reproducible --null | eval -- $compress >> "$out/initrd")

if [ -n "$makeUInitrd" ]; then
    mkimage -A "$uInitrdArch" -O linux -T ramdisk -C "$uInitrdCompression" -d "$out/initrd" $out/initrd.img
    # Compatibility symlink
    ln -sf "initrd.img" "$out/initrd"
else
    ln -s "initrd" "$out/initrd$extension"
fi
