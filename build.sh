export PATH="/home/kokuban/toolchainZ4/prebuilts/build-tools/linux-x86/bin:/home/kokuban/toolchainZ4/prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/bin:/home/kokuban/toolchainZ4/prebuilts-master/clang/host/linux-x86/clang-r416183b/bin:usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:/snap/bin:$PATH"

echo $PATH

set -e

TARGET_DEFCONFIG=${1:-taro_gki_defconfig}

cd "$(dirname "$0")"

LOCALVERSION=-Kokuban-android12-9-Bronya

if [ "$LTO" == "thin" ]; then
  LOCALVERSION+="-thin"
fi

ARGS="
CROSS_COMPILE=aarch64-linux-gnu-
CC=clang
ARCH=arm64
SUBARCH=arm64
LLVM=1 LLVM_IAS=1
LOCALVERSION=$LOCALVERSION
"

# build kernel
make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS} $TARGET_DEFCONFIG

./scripts/config --file out/.config \
  -d UH \
  -d RKP \
  -d KDP \
  -d SECURITY_DEFEX \
  -d INTEGRITY \
  -d FIVE \
  -d TRIM_UNUSED_KSYMS

if [ "$LTO" = "thin" ]; then
  ./scripts/config --file out/.config -e LTO_CLANG_THIN -d LTO_CLANG_FULL
fi

make -j$(nproc) -C $(pwd) O=$(pwd)/out ${ARGS}

cd out
if [ ! -d AnyKernel3 ]; then
  git clone --depth=1 https://github.com/YuzakiKokuban/AnyKernel3.git -b taro
fi
cp arch/arm64/boot/Image AnyKernel3/zImage
name=ZFold4_ZFlip4_${TARGET_DEFCONFIG%%_defconfig}_kernel_`cat include/config/kernel.release`_`date '+%Y_%m_%d'`
cd AnyKernel3
zip -r ${name}.zip * -x *.zip
echo "AnyKernel3 package output to $(realpath $name).zip"
