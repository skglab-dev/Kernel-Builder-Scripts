#!/usr/bin/env bash
#
# Copyright (C) 2022-2023 Neebe3289 <neebexd@gmail.com>
# Copyright (C) 2024-2025 nullptr03 <nullptr03@singkolab.my.id>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Script for krenel compilation !!

# Color Definition
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
LIGHT_RED='\033[1;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_BLUE='\033[1;34m'
LIGHT_YELLOW='\033[1;33m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[0m'

# Color print function
# Usage: a_print <color> <text>
# or
# Usage: a_print <text>
# No color provide will be white by default
a_print() {
  if [ "$1" = "g" ]; then
    COLOR=$GREEN
  elif [ "$1" = "r" ]; then
    COLOR=$RED
  elif [ "$1" = "b" ]; then
    COLOR=$BLUE
  elif [ "$1" = "y" ]; then
    COLOR=$YELLOW
  elif [ "$1" = "c" ]; then
    COLOR=$CYAN
  elif [ "$1" = "lr" ]; then
    COLOR=$LIGHT_RED
  elif [ "$1" = "lg" ]; then
    COLOR=$LIGHT_GREEN
  elif [ "$1" = "lb" ]; then
    COLOR=$LIGHT_BLUE
  elif [ "$1" = "ly" ]; then
    COLOR=$LIGHT_YELLOW
  elif [ "$1" = "lc" ]; then
    COLOR=$LIGHT_CYAN
  elif [ "$1" = "w" ]; then
    COLOR=$WHITE
  fi
  if [ ! -z "$1" ] && [ -z "$2" ]; then
    COLOR=$WHITE
    TEXT=$1
  else
    TEXT=$2
  fi
  echo -e "${COLOR}$TEXT${WHITE}"
}

# OS detection
export OS_ID="$(grep '^ID=' /etc/os-release | sed 's/ID=*//g')"

function show_help() {
  a_print lc "--ghconf      -g, --global,  Set git user.name and user.password for git project
--setup       Installing the build dependencies (auto os detection)
--setup2      Installing the build dependencies and start build (auto os detection)
--zip         Zipping the whole anykernel folder and upload it
--cleanup     Delete the anykernel and out folder
-h, --help    Show this help message"
}

function set_git_user() {
  if [ "$1" = "-g" ] || [ "$1" = "--global" ]; then
  git config --global user.name "$2"
  git config --global user.email "$3"
  a_print lg "Set global git config user to $2 <$3>"
  elif [ ! -z "$1" ]; then
  git config user.name "$2"
  git config user.email "$3"
  a_print lg "Set git config user to $2 <$3>"
  fi
}

function install_dependencies() {
  if [ "$OS_ID" = "ubuntu" ] || [ "$1" = "ubuntu" ]; then
    a_print lb "Installing build dependencies for Ubuntu"
    sudo apt-get update -y
    sudo apt-get -y install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
    gnupg gperf imagemagick protobuf-compiler python3-protobuf lib32readline-dev lib32z1-dev libdw-dev libelf-dev lz4 \
    libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
  elif [ "$OS_ID" = "debian" ] || [ "$1" = "debian" ]; then
    a_print lb "Installing build dependencies for Debian"
    sudo apt-get update -y
    sudo apt-get -y install bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
    gnupg gperf imagemagick protobuf-compiler python3-protobuf lib32readline-dev lib32z1-dev libdw-dev libelf-dev lz4 \
    libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
  elif [ "$OS_ID" = "fedora" ] || [ "$1" = "fedora" ]; then
    a_print lb "Installing build dependencies for Fedora"
    sudo dnf install -y bc bison ccache curl flex gmp-devel glibc-devel.i686 glibc-devel.x86_64 \
    gmp-devel.i686 gmp-devel.x86_64 git git-lfs gperf ImageMagick-devel.i686 ImageMagick-devel.x86_64 \
    libstdc++-devel.i686 libstdc++-devel.x86_64 libstdc++-static.i686 libstdc++-static.x86_64 \
    libxml2-devel.i686 libxml2-devel.x86_64 lz4-devel lzop make ncurses-devel.i686 ncurses-devel.x86_64 \
    openssl-devel.i686 openssl-devel.x86_64 perl-Protobuf python3-protobuf readline-devel.i686 readline-devel.x86_64 \
    rsync SDL-devel.i686 SDL-devel.x86_64 squashfs-tools wget which xz zip zlib-devel.i686 zlib-devel.x86_64
  elif [ "$OS_ID" = "arch" ] || [ "$1" = "arch" ]; then
    a_print lb "Installing build dependencies for Arch Linux"
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm bc bison ccache curl flex gmp git git-lfs gperf imagemagick \
    jdk-openjdk lib32-readline lib32-zlib libelf libelf-dev lz4 ncurses5-compat-libs \
    openssl protobuf python-pip readline rsync sdl lib32-sdl squashfs-tools xz zip zlib
  else
    a_print ly "Your operating system is $OS_ID, you may need to install the build dependencies manually"
  fi
}

function file_store_content() {
  if [ -f "$1" ]; then
    file_name="$1"
    file_content_data="$(cat $file_name1)"
    if [ ! -z "$file_content_data" ]; then
      file_content_stored=1
    fi
  fi
}

function file_restore_content() {
  if [ ! -z $file_content_stored ] && [ ! -z "$file_content_data" ] && [ -f "$file_name" ]; then
    echo "$file_content_data" > $file_name
    unset file_name
    unset file_content_data
    unset file_content_stored
  fi
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
show_help
elif [ "$1" = "--ghconf" ]; then
set_git_user $2 "nullptr03" "nullptr03@singkolab.my.id"
elif [ "$1" = "--setup" ]; then
install_dependencies $2
else

if [ "$1" = "--setup2" ]; then
install_dependencies $2
fi

# Load variables from config.env
set -a
source config.env
set +a

# Path
MainPath="$(readlink -f -- $(pwd))"
ChangelogPath=$MainPath
MainClangPath="${MainPath}/clang"
AnyKernelPath="${MainPath}/anykernel"
CrossCompileFlagTriple="aarch64-linux-gnu-"

# 
if [ -d "${MainPath}/common" ]; then
    BAZEL_BUILD="yes"
    a_print lg "Common kernel detected, use bazel build method."
else
    BAZEL_BUILD="no"
fi

if [ "$BAZEL_BUILD" = "yes" ]; then
    KernelPath="$MainPath/common"

    # build-tools
    if [ -d "${MainPath}/prebuilts/build-tools" ]; then
      AVBTOOL=$MainPath/prebuilts/kernel-build-tools/linux-x86/bin/avbtool
      BOOT_SIGN_KEY=$MainPath/prebuilts/kernel-build-tools/linux-x86/share/avb/testkey_rsa2048.pem
    fi
    if [ -d "${MainPath}/tools/mkbootimg" ]; then
      MKBOOTIMG=$MainPath/tools/mkbootimg/mkbootimg.py
      REPACK_BOOTIMG=$MainPath/tools/mkbootimg/repack_bootimg.py
      UNPACK_BOOTIMG=$MainPath/tools/mkbootimg/unpack_bootimg.py
    fi
else
    KernelPath="$MainPath"
fi

# Clone toolchain
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
function getclang() {
  if [ "${ClangName}" = "azure" ]; then
    if [ ! -f "${MainClangPath}-azure/bin/clang" ]; then
      a_print lb "Clang is set to azure, cloning it..."
      git clone https://gitlab.com/Panchajanya1999/azure-clang clang-azure --depth=1
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      wget -q "https://gist.github.com/dakkshesh07/240736992abf0ea6f0ee1d8acb57a400/raw/a835c3cf8d99925ca33cec3b210ee962904c9478/patch-for-old-glibc.sh" -O patch.sh && chmod +x patch.sh && ./patch.sh
      cd ..
    else
      a_print lg "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    if [ ! -f "${MainClangPath}-neutron/bin/clang" ]; then
      a_print lb "Clang is set to neutron, cloning it..."
      mkdir -p "${MainClangPath}"-neutron
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      curl -LOk "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
      chmod +x antman && ./antman -S
      ./antman --patch=glibc
      cd ..
    else
      a_print lg "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "proton" ]; then
    if [ ! -f "${MainClangPath}-proton/bin/clang" ]; then
      a_print lb "Clang is set to proton, cloning it..."
      git clone https://github.com/kdrag0n/proton-clang clang-proton --depth=1
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      a_print lg "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "zyc" ]; then
    if [ ! -f "${MainClangPath}-zyc/bin/clang" ]; then
      a_print lb "Clang is set to zyc, cloning it..."
      mkdir -p ${MainClangPath}-zyc
      cd clang-zyc
      wget -q $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
      tar -xf zyc-clang.tar.gz
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
      rm -f zyc-clang.tar.gz
      cd ..
    else
      a_print lg "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "greenforce" ]; then
    if [ ! -f "${MainClangPath}-greenforce/bin/clang" ]; then
      a_print lg "Clang is set to greenforce, cloning it..."
      mkdir -p ${MainClangPath}-greenforce
      cd clang-greenforce
      wget -q https://raw.githubusercontent.com/greenforce-project/greenforce_clang/main/get_latest_url.sh
      source get_latest_url.sh; rm -rf get_latest_url.sh
      wget -q $LATEST_URL_GZ -O "greenforce-clang.tar.gz"
      tar -xf greenforce-clang.tar.gz
      ClangPath="${MainClangPath}"-greenforce
      export PATH="${ClangPath}/bin:${PATH}"
      rm -f greenforce-clang.tar.gz
      cd ..
    else
      a_print lg "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-greenforce
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  else
    a_print lr "Incorrect clang name. Check config.env for clang names."
    exit 1
  fi
  cd ${ClangPath}
  if [ ! -f 'gitignore' ] || [ ! -f '.gitignore' ]; then
    touch .gitignore
    echo "*" >> .gitignore
  elif [ -f 'gitignore' ]; then
    mv gitignore .gitignore
  fi
  if [ -z $COMPILER_STRING ]; then
    if [ -f "${ClangPath}/bin/clang" ]; then
      export KBUILD_COMPILER_STRING="$(${ClangPath}/bin/clang --version | head -n 1)"
    else
      export KBUILD_COMPILER_STRING="Unknown"
    fi
  else
    export KBUILD_COMPILER_STRING="$COMPILER_STRING"
  fi
  cd ..
}

function updateclang() {
  [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
  if [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    a_print lb "Clang is set to neutron, checking for updates..."
    cd clang-neutron
    if [ "$(./antman -U | grep "Nothing to do")" = "" ];then
      ./antman --patch=glibc
    else
      a_print lg "No updates have been found, skipping"
    fi
    cd ..
    elif [ "${ClangName}" = "zyc" ]; then
      a_print lb "Clang is set to zyc, checking for updates..."
      cd clang-zyc
      ZycLatest="$(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt 2>/dev/null)"
      if [ "$(cat README.md | grep "Build Date : " | cut -d: -f2 | sed "s/ //g")" != "${ZycLatest}" ];then
        a_print lb "An update have been found, updating..."
        rm -rf ./*
        wget -q $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
        tar -xf zyc-clang.tar.gz
        rm -f zyc-clang.tar.gz
      else
        a_print lg "No updates have been found, skipping..."
      fi
      cd .. 
    elif [ "${ClangName}" = "azure" ]; then
      cd clang-azure
      git fetch -q origin main
      git pull origin main
      cd ..
    elif [ "${ClangName}" = "proton" ]; then
      cd clang-proton
      git fetch -q origin master
      git pull origin master
      cd ..
  fi

  cd ${ClangPath}
  if [ ! -f 'gitignore' ] || [ ! -f '.gitignore' ]; then
    touch .gitignore
    echo "*" >> .gitignore
  elif [ -f 'gitignore' ]; then
    mv gitignore .gitignore
  fi
  cd ..
}

function clonegcc() {
  if [ "$CLANG_ONLY" = "yes" ]; then
    CrossCompileFlag64="aarch64-linux-gnu-"
    CrossCompileFlag32="arm-linux-gnueabi-"
  else
    if [ "$ENABLE_GCC64" = "yes" ];then
        if [[ ! -d "${MainPath}/gcc-64" ]]; then
          git clone https://github.com/rokibhasansagar/linaro-toolchain-latest.git -b latest-7 --depth=1 gcc-64
        fi
        CrossCompileFlag64="${MainPath}/gcc-64/bin/aarch64-linux-gnu-"
    else
        CrossCompileFlag64="aarch64-linux-gnu-"
    fi
    if [ "$ENABLE_GCC32" = "yes" ]; then
        if [[ ! -d "${MainPath}/gcc-32" ]]; then
          mkdir gcc-32
          wget -q -O gcc-arm.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz
          tar -C gcc-32/ -zxvf gcc-arm.tar.gz
          rm -rf gcc-arm.tar.gz
        fi
        CrossCompileFlag32="${MainPath}/gcc-32/bin/arm-linux-androideabi-"
    else
        CrossCompileFlag32="arm-linux-gnueabi-"
    fi
  fi
}

ak_store_script_content() {
  stored_ak_script_content="$(cat ${AnyKernelPath}/anykernel.sh)"
}

ak_restore_script_content() {
  if [ ! -z "$stored_ak_script_content" ]; then
    echo "$stored_ak_script_content" > ${AnyKernelPath}/anykernel.sh
    unset stored_ak_script_content
  fi
}

ak_update_kernel_name() {
  sed -i "s/kernel.string=*/kernel.string=$KERNEL_NAME by $KBUILD_BUILD_USER@$KBUILD_BUILD_HOST/g" ${AnyKernelPath}/anykernel.sh
}

defconfig_store_content() {
  stored_defconfig_contenet="$(cat $DEFCONFIG_FILE)"
}

defconfig_restore_content() {
  if [ ! -z "$stored_defconfig_contenet" ]; then
    echo "$stored_defconfig_contenet" > $DEFCONFIG_FILE
    unset stored_defconfig_contenet
  fi
}

load_device_defconfig() {
  DEFCONFIG_FILE="${KernelPath}/arch/${ARCH}/configs/${DEVICE_DEFCONFIG}"
  if [ ! -f "$DEFCONFIG_FILE" ]; then
    a_print lr "$DEVICE_DEFCONFIG config does not exists, abortting!"
    exit 1
  fi
  defconfig_store_content
}

unload_device_defconfig() {
  if [ ! -z "$DEFCONFIG_FILE" ]; then
    unset DEFCONFIG_FILE
    DEFCONFIG_FILE=no_defconfig
  fi
}

load_device_defconfig

restoreLocalVersion() {
  if [ ! -z "$stored_localversion_contenet" ]; then
    echo "$stored_localversion_contenet" > "${KernelPath}/localversion"
    unset stored_localversion_contenet
  fi
}

restoreLocalVersionNoCheck() {
  echo "$stored_localversion_contenet" > "${KernelPath}/localversion"
  unset stored_localversion_contenet
}

storeLocalVersion() {
  stored_localversion_contenet="$(cat ${KernelPath}/localversion)"
}

# root-function
function ksu_patch() {
  IS_KERNELSU_CONFIG_EXISTS="$(grep '^CONFIG_KSU=' ${DEFCONFIG_FILE})"

  if [ ! -z "$IS_KERNELSU_CONFIG_EXISTS" ]; then
    if [ "$KERNELSU" = "lkm" ]; then
      sed -i "s/CONFIG_KSU=n/CONFIG_KSU=m/g" $DEFCONFIG_FILE
    else
      if [ "$KERNELSU" = "yes" ]; then
        sed -i "s/CONFIG_KSU=n/CONFIG_KSU=y/g" $DEFCONFIG_FILE
      else
        sed -i "s/CONFIG_KSU=y/CONFIG_KSU=n/g" $DEFCONFIG_FILE
      fi
    fi
    IS_KERNELSU="$(grep '^CONFIG_KSU=' ${DEFCONFIG_FILE} | sed 's/CONFIG_KSU=*//g')"
  fi
}

# Function of telegram
if [ "$TELEGRAM_ANNOUNCE" = "yes" ]; then
if [ ! -f "${MainPath}/Telegram/telegram" ]; then
  git clone --depth=1 https://github.com/fabianonline/telegram.sh Telegram
fi
TELEGRAM="${MainPath}/Telegram/telegram"

# Telegram message sending function
tgm() {
  "${TELEGRAM}" -H -D \
      "$(
          for POST in "${@}"; do
              echo "${POST}"
          done
      )"
}

# Telegram file sending function
tgf() {
  "${TELEGRAM}" -H \
  -f "$1" \
  "$2"
}

tgannounce() {
  "${TELEGRAM}" -c ${TELEGRAM_CHANNEL} -H \
  -f "$1" \
  "$2"
}
else
tgm() { 
  2>/dev/null
}
tgf() { 
  2>/dev/null
}
tgannounce() { 
  2>/dev/null
}
fi

function upload() {
  #if [ ! -f "/var/www/html/$1" ] then
  #  rm -rf /var/www/html/$1
  #fi
  #mv $1 /var/www/html/
  #echo "http://128.199.250.112/$1"
  curl -F "file=@$1" https://temp.sh/upload
  echo 
}

# Changelog
changelogs() {
  if [ $ENABLE_CHANGELOG = "yes" ]; then
    a_print lb "Generating changelog from git log..."

    if [ -z $1 ]; then
      LOG_NUM=200
    else
      LOG_NUM=$1
    fi

    old_path="$(pwd)"
    cd $KernelPath
    git log -n $LOG_NUM --pretty=format:"$CHANGELOG_FORMAT" > "$ChangelogPath/$CHANGELOG_FILE_NAME"
    sed -i -e "s/^/- /" "$ChangelogPath/$CHANGELOG_FILE_NAME"
    cd $old_path
    
    GENERATED_CHANGELOG="$(head -n "$TELEGRAM_MAX_CHANGELOG" "${ChangelogPath}/${CHANGELOG_FILE_NAME}")"
    PRINT_CHANGELOG="
Changelog (GitHub):
<blockquote expandable>$GENERATED_CHANGELOG</blockquote>"
  else
    PRINT_CHANGELOG=""
  fi
}

# Enviromental variable
BUILD_DATE="$(date "+%Y%m%d")"
BUILD_DATE2="$(date "+%B %d, %Y")"
VERSION="$(grep '^VERSION = ' ${KernelPath}/Makefile | sed 's/VERSION = *//g')"
PATCHLEVEL="$(grep '^PATCHLEVEL = ' ${KernelPath}/Makefile | sed 's/PATCHLEVEL = *//g')"
SUBLEVEL="$(grep '^SUBLEVEL = ' ${KernelPath}/Makefile | sed 's/SUBLEVEL = *//g')"
KERNELVERSION="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}"

if [ $USE_CUSTOM_LOCALVERSION = "yes" ]; then
  if [ ! -z $CUSTOM_LOCALVERSION ]; then
    storeLocalVersion
    echo -n "-$CUSTOM_LOCALVERSION" > ${KernelPath}/localversion
  fi
  if [[ -f "${KernelPath}/localversion" ]]; then
    export LOCALVERSION="$(cat "${KernelPath}/localversion")"
  else
    export LOCALVERSION="$(grep '^CONFIG_LOCALVERSION=' $DEFCONFIG_FILE | sed 's/CONFIG_LOCALVERSION=*//g')"
  fi
else
  export LOCALVERSION=
fi

# Level (0 = none, 1 = gz, 2 = lz4)
if [ "$KERNEL_COMPRESSION" = "none" ]; then
  BOOT_NAME_PREFIX=""
  KERNEL_IMAGE_NAME="Image"
  KERNEL_COMPRESSION_LEVEL=0
  KERNEL_COMPRESSION_LEVEL_NAME=""
elif [ "$KERNEL_COMPRESSION" = "gz" ]; then
  BOOT_NAME_PREFIX="-"
  KERNEL_IMAGE_NAME="Image.gz"
  KERNEL_COMPRESSION_LEVEL=1
  KERNEL_COMPRESSION_LEVEL_NAME="gz"
elif [ "$KERNEL_COMPRESSION" = "lz4" ]; then
  BOOT_NAME_PREFIX="-"
  KERNEL_IMAGE_NAME="Image.lz4"
  KERNEL_COMPRESSION_LEVEL=2
  KERNEL_COMPRESSION_LEVEL_NAME="lz4"
else
  a_print lr "Kernel Compression is $KERNEL_COMPRESSION which is unknown by compiler"
  BOOT_NAME_PREFIX=""
  KERNEL_IMAGE_NAME="Image"
  KERNEL_COMPRESSION_LEVEL=0
  KERNEL_COMPRESSION_LEVEL_NAME=""
fi
KERNEL_BOOTIMG_NAME="boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME"

if [ "$BAZEL_BUILD" = "yes" ]; then
    IMAGE="${MainPath}/bazel-bin/common/kernel_aarch64/$KERNEL_IMAGE_NAME"
else
    IMAGE="${MainPath}/out/arch/arm64/boot/$KERNEL_IMAGE_NAME"
fi

getdtb() {
  if [ "$USING_DTB" = "prebuilt" ]; then
    if [ ! -z "$PREBUILT_DTBLINK" ]; then
      if [ -f "dtb" ]; then
        rm -rf dtb
      fi
      wget -q $PREBUILT_DTBLINK -O "dtb"
    fi
      if [ -f "dtbo" ]; then
        rm -rf dtbo
      fi
    if [ ! -z "$PREBUILT_DTBOLINK" ]; then
      wget -q $PREBUILT_DTBOLINK -O "dtbo"
    fi
  elif [ "$USING_DTB" = "custom" ]; then
    DTS_DIR="${MainPath}/out/arch/arm64/boot/dts/vendor/$ARCH_VENDOR"
    DTB_FILE="$DTS_DIR/blair.dtb"
    DTBO_FILE="${MainPath}/out/arch/arm64/boot/dtbo.img"
  else
    a_print lr "USING_DTB config is not set, skipping DTB."
  fi
}

if [ "$IS_KERNELSU" = "m" ]; then
  BUILD_VARIANT="KernelSU (LKM)"
elif [ "$IS_KERNELSU" = "y" ]; then
  BUILD_VARIANT="KernelSU"
else
  BUILD_VARIANT="Non-KSU"
fi

if [ "$USING_BOOTIMG" = "yes" ]; then
  KERNEL_ZIP="${KERNEL_NAME}-boot-${DEVICE_CODENAME}-${BUILD_DATE}.zip"
else
  KERNEL_ZIP="${KERNEL_NAME}-${DEVICE_CODENAME}-${BUILD_DATE}.zip"
fi

GenerateBootImage() {
  a_print lg "Generating $KERNEL_BOOTIMG_NAME..."
  $MKBOOTIMG --header_version 4 --kernel $KERNEL_IMAGE_NAME --output boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME.img
  $AVBTOOL add_hash_footer --partition_name boot --partition_size $((64 * 1024 * 1024)) --image boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME.img --algorithm SHA256_RSA2048 --key $BOOT_SIGN_KEY
  a_print lb "$KERNEL_BOOTIMG_NAME generated succesfully."
}

# Start Compile
CORES="$(nproc --all)"
START=$(date +"%s")

StartMake() {
  make O=out ARCH=$ARCH $DEVICE_DEFCONFIG
  if [ "$CLANG_ONLY" = "yes" ]; then
    make -j"$CORES" ARCH=$ARCH O=out \
      CC=clang \
      LD=ld.lld \
      LLVM=1 \
      LLVM_IAS=1 \
      AR=llvm-ar \
      NM=llvm-nm \
      OBJCOPY=llvm-objcopy \
      OBJDUMP=llvm-objdump \
      STRIP=llvm-strip \
      CLANG_TRIPLE=${CrossCompileFlagTriple} \
      CROSS_COMPILE=${CrossCompileFlag64} \
      CROSS_COMPILE_ARM32=${CrossCompileFlag32}
  else
    make -j"$CORES" ARCH=$ARCH O=out \
      CC=clang \
      CLANG_TRIPLE=${CrossCompileFlagTriple} \
      CROSS_COMPILE=${CrossCompileFlag64} \
      CROSS_COMPILE_ARM32=${CrossCompileFlag32}
  fi
}

compile(){
  tgm "Kernel Compilation for $DEVICE_MODEL has been started

Kernel Version: $KERNELVERSION$LOCALVERSION
Kernel Variant: $BUILD_VARIANT
Kernel Codename: $CODENAME
Compiler: $KBUILD_COMPILER_STRING"

  if [ "$BAZEL_BUILD" = "yes" ]; then
      tools/bazel build --config=fast --lto=thin //common:kernel_aarch64_dist
  else
    if [ "$ClangName" = "proton" ]; then
        sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' $DEFCONFIG_FILE || echo ""
    else
        sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' $DEFCONFIG_FILE || echo ""
    fi

    if [ "$ENABLE_OUTPUT_LOG" = "yes" ]; then
      StartMake |& tee out/output.log
    else
      StartMake
    fi
  fi
  
  if [[ -f "$IMAGE" ]]; then
    cd ${MainPath}
    if [ "$USING_BOOTIMG" = "yes" ]; then
      a_print lg "Building $KERNEL_BOOTIMG_NAME.img"

      if [ ! -d "bootimgs" ]; then
        mkdir bootimgs
      fi
      cd bootimgs
      cp $IMAGE ./$KERNEL_IMAGE_NAME
      GenerateBootImage

      if [ -f "$KERNEL_BOOTIMG_NAME.img" ]; then
        cd $KernelPath
        changelogs
        cd $MainPath
        zipping
      else
        a_print lr "Failed to build $KERNEL_BOOTIMG_NAME, , Check console log to fix it!"
      fi

      cd ${MainPath}
    else
      if [ ! -d "${AnyKernelPath}" ]; then
        git clone -q --depth=1 ${AnyKernelRepo} -b ${AnyKernelBranch} ${AnyKernelPath}
      fi
      cp $IMAGE ${AnyKernelPath}

      if [ "$USING_DTB" = "prebuilt" ]; then
        cp $DTB_FILE ${AnyKernelPath}/dtb
        cp $DTBO_FILE ${AnyKernelPath}/dtbo
      elif [ "$USING_DTB" = "custom" ]; then
        python3 scripts/mkdtboimg.py create ${AnyKernelPath}/dtbo --page_size=4096 $DTBO_FILE
      fi

      changelogs
      zipping
    fi
  else
    BUILD_RESULT="❌ Compile Kernel for $DEVICE_MODEL failed, Check console log to fix it!"
    a_print lr "$BUILD_RESULT"
    if [ "$BAZEL_BUILD" = "yes" ]; then
      tgm "$BUILD_RESULT"
    else
      tgannounce "out/output.log" "$BUILD_RESULT"
    fi
    cleanup
    exit 1
  fi
}

# Zipping function
function zipping() {
  if [ "$USING_BOOTIMG" = "yes" ]; then
    zip -q -r9 ${KERNEL_ZIP} "boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME.img" "$CHANGELOG_FILE_NAME"
  else
    cd ${AnyKernelPath} || exit 1
    ak_store_script_content
    ak_update_kernel_name
    if [ -f "${ChangelogPath}/$CHANGELOG_FILE_NAME" ]; then
      cp ${ChangelogPath}/$CHANGELOG_FILE_NAME ./
    fi
    getdtb
    zip -q -r9 ${KERNEL_ZIP} * -x .git README.md *placeholder
  fi

  END=$(date +"%s")
  DIFF=$(( $END - $START ))

  #upload ${KERNEL_ZIP}
  BUILD_RESULT="✅ Compile Kernel for $DEVICE_MODEL successfully,

Build date: $BUILD_DATE2
Kernel Version: $KERNELVERSION$LOCALVERSION
Kernel Variant: $BUILD_VARIANT
Kernel Codename: $CODENAME
Compiler: $KBUILD_COMPILER_STRING

Completed in $(($DIFF/3600)) hours $(($DIFF %3600 / 60)) minutes and $(($DIFF % 60)) seconds.

$PRINT_CHANGELOG"

  a_print lg "File: ${AnyKernelPath}/${KERNEL_ZIP}"
  a_print lc "
    Compilation took $(($DIFF/3600)) hours $(($DIFF %3600 / 60)) minutes and $(($DIFF % 60)) seconds."

  #echo $BUILD_RESULT
  tgannounce $KERNEL_ZIP "$BUILD_RESULT"
  cd ..
  cleanup
}

# Cleanup function
function cleanup() {
  cd ${MainPath}
  rm -rf $IMAGE
  if [ "$CLEANUP" = "yes" ] || [ "$1" = "--cleanup" ]; then
    a_print lb "Cleaning up..."
    rm -rf ${AnyKernelPath}
    rm -rf out/
    a_print lg "Cleanup done."
  fi

  restoreLocalVersionNoCheck
  ak_restore_script_content
  defconfig_restore_content
}

function ctrl_c() {
  END=$(date +"%s")
  DIFF=$(( $END - $START ))

  BUILD_RESULT="❌ Compile Kernel for $DEVICE_MODEL was interrupted!
  
Reason: CtrL+C detected."

  tgm "$BUILD_RESULT"
  a_print lr "$BUILD_RESULT"
  cleanup
  exit 1
}

trap ctrl_c INT

if [ "$1" = "--zip" ] || [ "$1" = "--zipping" ]; then
if [ ! -d "${AnyKernelPath}" ]; then
  git clone -q --depth=1 ${AnyKernelRepo} -b ${AnyKernelBranch} ${AnyKernelPath}
fi
changelogs
zipping
ak_restore_script_content
else
if [ "$BAZEL_BUILD" = "no" ]; then
getclang
updateclang
clonegcc
fi
ksu_patch
compile
#zipping
cleanup

fi
fi
