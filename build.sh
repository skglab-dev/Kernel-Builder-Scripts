#!/usr/bin/env bash
#
# Copyright (C) 2022-2023 Neebe3289 <neebexd@gmail.com>
# Copyright (C) 2024-2026 nullptr03 <nullptr03@singkolab.my.id>
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

var="${1:-}"

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
  local color="$WHITE"

  case "$1" in
    g) color=$GREEN ;;
    r) color=$RED ;;
    b) color=$BLUE ;;
    y) color=$YELLOW ;;
    c) color=$CYAN ;;
    lr) color=$LIGHT_RED ;;
    lg) color=$LIGHT_GREEN ;;
    lb) color=$LIGHT_BLUE ;;
    ly) color=$LIGHT_YELLOW ;;
    lc) color=$LIGHT_CYAN ;;
  esac

  echo -e "${color}${2:-$1}${WHITE}"
}

set -a
source config.env
set +a

# OS detection
export OS_ID="$(grep '^ID=' /etc/os-release | sed 's/ID=*//g')"

show_help() {
  a_print lc "--ghconf      -g, --global,  Set git user.name and user.email for git project
--setup       Installing the build dependencies (auto os detection)
--cleanup     Delete the anykernel and out folder
-z, --zip     Zipping the whole anykernel folder and upload it
-c, --clean   Start a clean build
-h, --help    Show this help message"
}

set_git_user() {
  if [ "$1" = "-g" ] || [ "$1" = "--global" ]; then
  git config --global user.name "$DEFAULT_GIT_USER"
  git config --global user.email "$DEFAULT_GIT_EMAIL"
  a_print lg "Set global git config user to $DEFAULT_GIT_USER <$DEFAULT_GIT_EMAIL>"
  elif [ ! -z "$1" ]; then
  git config user.name "$DEFAULT_GIT_USER"
  git config user.email "$DEFAULT_GIT_EMAIL"
  a_print lg "Set git config user to $DEFAULT_GIT_USER <$DEFAULT_GIT_EMAIL>"
  fi
}

install_dependencies() {
  local distro="${1:-$OS_ID}"

  local apt_pkgs="bc bison build-essential ccache curl flex g++-multilib gcc-multilib git git-lfs \
gnupg gperf imagemagick protobuf-compiler python3-protobuf lib32readline-dev lib32z1-dev \
libdw-dev libelf-dev lz4 libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush \
rsync schedtool squashfs-tools xsltproc zip zlib1g-dev"

  case "$distro" in
    ubuntu|neon|debian)
      a_print lb "Installing build dependencies for ${distro^}"
      sudo apt-get update -y
      sudo apt-get install -y $apt_pkgs
      ;;
    fedora)
      a_print lb "Installing build dependencies for Fedora"
      sudo dnf install -y bc bison ccache curl flex gmp-devel glibc-devel.i686 glibc-devel.x86_64 \
      gmp-devel.i686 gmp-devel.x86_64 git git-lfs gperf ImageMagick-devel.i686 ImageMagick-devel.x86_64 \
      libstdc++-devel.i686 libstdc++-devel.x86_64 libstdc++-static.i686 libstdc++-static.x86_64 \
      libxml2-devel.i686 libxml2-devel.x86_64 lz4-devel lzop make ncurses-devel.i686 ncurses-devel.x86_64 \
      openssl-devel.i686 openssl-devel.x86_64 perl-Protobuf python3-protobuf readline-devel.i686 readline-devel.x86_64 \
      rsync SDL-devel.i686 SDL-devel.x86_64 squashfs-tools wget which xz zip zlib-devel.i686 zlib-devel.x86_64
      ;;
    arch)
      a_print lb "Installing build dependencies for Arch Linux"
      sudo pacman -Syu --noconfirm
      sudo pacman -S --needed bc cpio bison base-devel ccache curl flex gcc gcc-multilib git git-lfs \
      gnupg gperf imagemagick protobuf python-protobuf lib32-readline lib32-zlib elfutils lz4 \
      sdl lib32-gcc-libs openssl libxml2 lzop pngcrush rsync squashfs-tools libxslt zip zlib
      ;;
    *)
      a_print ly "Your operating system is $OS_ID, you may need to install the build dependencies manually"
      ;;
  esac
}

DIRECT_ZIPPING=0

case "$var" in
  -h|--help) show_help; exit 1 ;;
  --ghconf) set_git_user "$2"; exit 1 ;;
  --setup) install_dependencies "$@"; exit 1 ;;
  -z|--zip) DIRECT_ZIPPING=1 ;;
esac

# add version to kernel name
KERNEL_NAME+="-$KERNEL_VERS"

a_print lb "Compiling for $DEVICE_MODEL started."

# Path
MainPath="$(readlink -f -- $(pwd))"
ChangelogPath=$MainPath
MainClangPath="${MainPath}/clang"
AnyKernelPath="${MainPath}/anykernel"
CrossCompileFlagTriple="aarch64-linux-gnu-"

IS_AK3_EXISTS=$([[ -d "$AnyKernelPath" ]] && echo 1 || echo 0)

#
BAZEL_BUILD=$([[ -d "$MainPath/common" ]] && echo 1 || echo 0)

[[ "$BAZEL_BUILD" -eq 1 ]] && \
  a_print lg "Common kernel detected, use bazel build method."

KernelPath="$MainPath"
if [[ "$BAZEL_BUILD" -eq 1 ]]; then
  KernelPath="$MainPath/common"

  [[ -d "$MainPath/prebuilts/kernel-build-tools" ]] && {
    AVBTOOL="$MainPath/prebuilts/kernel-build-tools/linux-x86/bin/avbtool"
    BOOT_SIGN_KEY="$MainPath/prebuilts/kernel-build-tools/linux-x86/share/avb/testkey_rsa2048.pem"
  }

  [[ -d "$MainPath/tools/mkbootimg" ]] && {
    MKBOOTIMG="$MainPath/tools/mkbootimg/mkbootimg.py"
    REPACK_BOOTIMG="$MainPath/tools/mkbootimg/repack_bootimg.py"
    UNPACK_BOOTIMG="$MainPath/tools/mkbootimg/unpack_bootimg.py"
  }
fi

getcompilerString() {
  if [ -z "$COMPILER_STRING" ]; then
    if [[ "$BAZEL_BUILD" -eq 1 ]]; then
      export KBUILD_COMPILER_STRING="Bazel"
    else
      if [ -f "${ClangPath}/bin/clang" ]; then
        export KBUILD_COMPILER_STRING="$(${ClangPath}/bin/clang --version | head -n 1)"
      else
        export KBUILD_COMPILER_STRING="Unknown"
      fi
    fi
  else
    export KBUILD_COMPILER_STRING="$COMPILER_STRING"
  fi
  if [ -z "$LINKER_STRING" ]; then
    if [ -f "${ClangPath}/bin/ld.lld" ]; then
      export KBUILD_LINKER_STRING="$(ld.lld --version)"
    else
      export KBUILD_LINKER_STRING="Unknown"
    fi
  else
    export KBUILD_LINKER_STRING="$LINKER_STRING"
  fi
}

fixClangGitIgnore() {
  if [ ! -f '.gitignore' ]; then
    touch .gitignore
    echo "*" >> .gitignore
  elif [ -f 'gitignore' ]; then
    mv gitignore .gitignore
  fi
}

# Clone toolchain
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
getclang() {
  local name="${ClangName:-neutron}"

  case "$name" in
      azure)      ClangPath="${MainClangPath}-azure" ;;
      neutron)    ClangPath="${MainClangPath}-neutron" ;;
      proton)     ClangPath="${MainClangPath}-proton" ;;
      zyc)        ClangPath="${MainClangPath}-zyc" ;;
      greenforce) ClangPath="${MainClangPath}-greenforce" ;;
      *)
          a_print lr "Incorrect clang name. Check config.env for clang names."
          exit 1
          ;;
  esac

  export PATH="${ClangPath}/bin:${PATH}"

  if [[ -f "${ClangPath}/bin/clang" ]]; then
    a_print lg "Clang already exists. Skipping..."
  else
    a_print lb "Clang is set to ${name}, cloning it..."

  case "$name" in
    azure)
      git clone -q --depth=1 \
          https://gitlab.com/Panchajanya1999/azure-clang \
          "${ClangPath}"
      (
          cd "${ClangPath}" || exit
          wget -q \
              "https://gist.github.com/dakkshesh07/240736992abf0ea6f0ee1d8acb57a400/raw/a835c3cf8d99925ca33cec3b210ee962904c9478/patch-for-old-glibc.sh" \
              -O patch.sh
          chmod +x patch.sh
          ./patch.sh
      )
      ;;
    neutron)
      mkdir -p "${ClangPath}"
      (
          cd "${ClangPath}" || exit
          curl -LOks \
              https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman
          chmod +x antman
          ./antman -S
          ./antman --patch=glibc
      )
      ;;
    proton)
      git clone -q --depth=1 \
          https://github.com/kdrag0n/proton-clang \
          "${ClangPath}"
      ;;
    zyc)
      mkdir -p "${ClangPath}"

      (
          cd "${ClangPath}" || exit
          wget -q \
              "$(curl -ks https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt)" \
              -O zyc-clang.tar.gz
          tar -xf zyc-clang.tar.gz
          rm -f zyc-clang.tar.gz
      )
      ;;
    greenforce)
      mkdir -p "${ClangPath}"
      (
          cd "${ClangPath}" || exit
          wget -q \
              https://raw.githubusercontent.com/greenforce-project/greenforce_clang/main/get_latest_url.sh
          source get_latest_url.sh
          rm -f get_latest_url.sh
          wget -q "$LATEST_URL" -O greenforce-clang.tar.gz
          tar -xf greenforce-clang.tar.gz
          rm -f greenforce-clang.tar.gz
      )
      ;;
    esac
  fi
  (
    cd "${ClangPath}" || exit
    fixClangGitIgnore
  )
}

updateclang() {
  case "${ClangName:-neutron}" in
    neutron)
      a_print lb "Clang is set to neutron, checking for updates..."
      (
          cd clang-neutron || exit

          if ! ./antman -U | grep -q "Nothing to do"; then
              ./antman --patch=glibc
          else
              a_print lg "No updates have been found, skipping..."
          fi
      )
      ;;
    zyc)
      a_print lb "Clang is set to zyc, checking for updates..."
      (
          cd clang-zyc || exit

          local latest current

          latest="$(curl -ks https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt)"
          current="$(grep "Build Date :" README.md | cut -d: -f2 | tr -d ' ')"

          if [[ "$current" != "$latest" ]]; then
              a_print lb "An update has been found, updating..."

              rm -rf ./*
              wget -q \
                  "$(curl -ks https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt)" \
                  -O zyc-clang.tar.gz
              tar -xf zyc-clang.tar.gz
              rm -f zyc-clang.tar.gz
          else
              a_print lg "No updates have been found, skipping..."
          fi
      )
      ;;
    azure)
      (
          cd clang-azure || exit
          git pull -q origin main
      )
      ;;
    proton)
      (
          cd clang-proton || exit
          git pull -q origin master
      )
      ;;
  esac
  (
    cd "${ClangPath}" || exit
    fixClangGitIgnore
  )
}

clonegcc() {
  if [[ "$CLANG_ONLY" -eq 1 ]]; then
    CrossCompileFlag64="aarch64-linux-gnu-"
    CrossCompileFlag32="arm-linux-gnueabi-"
    return
  fi

  if [[ "$ENABLE_GCC64" -eq 1 ]]; then
    [[ -d "$MainPath/gcc-64" ]] || git clone -q --depth=1 -b latest-7 \
        https://github.com/rokibhasansagar/linaro-toolchain-latest.git gcc-64
    CrossCompileFlag64="$MainPath/gcc-64/bin/aarch64-linux-gnu-"
  else
    CrossCompileFlag64="aarch64-linux-gnu-"
  fi

  if [[ "$ENABLE_GCC32" -eq 1 ]]; then
    [[ -d "$MainPath/gcc-32" ]] || {
        mkdir -p gcc-32
        wget -qO gcc-arm.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz
        tar -C gcc-32 -zxf gcc-arm.tar.gz >/dev/null 2>&1
        rm -f gcc-arm.tar.gz
    }
    CrossCompileFlag32="$MainPath/gcc-32/bin/arm-linux-androideabi-"
  else
    CrossCompileFlag32="arm-linux-gnueabi-"
  fi
}

ak_store_script_content() {
  stored_ak_script_content="$(<"$AnyKernelPath/anykernel.sh")"
}

ak_restore_script_content() {
  if [ ! -z "$stored_ak_script_content" ]; then
    printf '%s' "$stored_ak_script_content" > "$AnyKernelPath/anykernel.sh"
    unset stored_ak_script_content
  fi
}

ak_update_kernel_name() {
  sed -i "s/kernel.string=*/kernel.string=$KERNEL_NAME by $KBUILD_BUILD_USER@$KBUILD_BUILD_HOST/g" ${AnyKernelPath}/anykernel.sh
}

defconfig_store_content() {
  stored_defconfig_content="$(<"$DEFCONFIG_FILE")"
}

defconfig_restore_content() {
  if [ ! -z "$stored_defconfig_contenet" ]; then
    printf '%s' "$stored_defconfig_content" > "$DEFCONFIG_FILE"
    unset stored_defconfig_contenet
  fi
}

load_device_defconfig() {
  DEFCONFIG_FILE="$KernelPath/arch/$ARCH/configs/$(
    [[ "$ENABLE_MULTICONFIG" -eq 1 ]] &&
    printf 'vendor/%s' "$FRAGMENT_CONFIG" ||
    printf '%s' "$DEVICE_DEFCONFIG"
  )"
  [[ -f "$DEFCONFIG_FILE" ]] || {
    a_print lr "$(
      [[ "$ENABLE_MULTICONFIG" -eq 1 ]] &&
      echo "$FRAGMENT_CONFIG fragment config does not exist, aborting!" ||
      echo "$DEVICE_DEFCONFIG config does not exist, aborting!"
    )"
    exit 1
  }
  defconfig_store_content
}

unload_device_defconfig() {
  DEFCONFIG_FILE=no_defconfig
}

load_device_defconfig

restoreLocalVersion() {
  [[ -n "$stored_localversion_content" ]] || return
  printf '%s' "$stored_localversion_content" > "$KernelPath/localversion"
  unset stored_localversion_contenet
}

restoreLocalVersionNoCheck() {
  printf '%s' "$stored_localversion_content" > "$KernelPath/localversion"
  unset stored_localversion_contenet
}

storeLocalVersion() {
  stored_localversion_content="$(<"$KernelPath/localversion")"
}

cloneAK3() {
  if [[ ! -d "$AnyKernelPath" ]]; then
    git clone -q --depth=1 -b "$AnyKernelBranch" "$AnyKernelRepo" "$AnyKernelPath"
    IS_AK3_EXISTS=1
  fi
}

# root-function
ksu_patch() {
  grep -q '^CONFIG_KSU=' "$DEFCONFIG_FILE" || {
      IS_KERNELSU=n
      return
  }
  case "$KERNELSU" in
      2) sed -i 's/CONFIG_KSU=n/CONFIG_KSU=m/' "$DEFCONFIG_FILE" ;;
      1) sed -i 's/CONFIG_KSU=n/CONFIG_KSU=y/' "$DEFCONFIG_FILE" ;;
      *) sed -i 's/CONFIG_KSU=y/CONFIG_KSU=n/' "$DEFCONFIG_FILE" ;;
  esac
  IS_KERNELSU="$(grep '^CONFIG_KSU=' "$DEFCONFIG_FILE" | cut -d= -f2)"
}

# Function of telegram
if [[ "$TELEGRAM_ANNOUNCE" -eq 1 ]]; then
  TELEGRAM="$MainPath/Telegram/telegram"

  [[ -f "$TELEGRAM" ]] || git clone -q --depth=1 \
      https://github.com/fabianonline/telegram.sh \
      "$MainPath/Telegram"

  tgm() {
      "$TELEGRAM" -H -D "$(printf '%s\n' "$@")"
  }
  tgf() {
      "$TELEGRAM" -H -f "$1" "$2"
  }
  tgannounce() {
      "$TELEGRAM" -c "$TELEGRAM_CHANNEL" -H -f "$1" "$2"
  }
else
  tgm() { :; }
  tgf() { :; }
  tgannounce() { :; }
fi

# Changelog
changelogs() {
    [[ "$ENABLE_CHANGELOG" -eq 1 ]] || { PRINT_CHANGELOG=""; return; }

    a_print lb "Generating changelog from git log..."

    local log_num="${1:-200}"

    git -C "$KernelPath" log -n "$log_num" \
        --pretty=format:"$CHANGELOG_FORMAT" \
        > "$ChangelogPath/$CHANGELOG_FILE_NAME"

    sed -i 's/^/- /' "$ChangelogPath/$CHANGELOG_FILE_NAME"

    if [[ ${TELEGRAM_MAX_CHANGELOG:-0} -gt 0 ]]; then
        GENERATED_CHANGELOG="$(head -n "$TELEGRAM_MAX_CHANGELOG" "$ChangelogPath/$CHANGELOG_FILE_NAME")"
        PRINT_CHANGELOG="Changelog (GitHub):
<blockquote expandable>$GENERATED_CHANGELOG</blockquote>"
    else
        PRINT_CHANGELOG=""
    fi
}

# Enviromental variable
BUILD_DATE="$(date "+%Y%m%d")"
BUILD_DATE2="$(date "+%B %d, %Y")"
KBUILD_BUILD_TIMESTAMP="$(date)"
KBUILD_BUILD_VERSION="1"
VERSION="$(grep '^VERSION = ' ${KernelPath}/Makefile | sed 's/VERSION = *//g')"
PATCHLEVEL="$(grep '^PATCHLEVEL = ' ${KernelPath}/Makefile | sed 's/PATCHLEVEL = *//g')"
SUBLEVEL="$(grep '^SUBLEVEL = ' ${KernelPath}/Makefile | sed 's/SUBLEVEL = *//g')"
KERNELVERSION="${VERSION}.${PATCHLEVEL}.${SUBLEVEL}"

if [[ "$USE_CUSTOM_LOCALVERSION" -eq 1 ]]; then
  if [[ -n "$CUSTOM_LOCALVERSION" ]]; then
    storeLocalVersion
    [[ "$USE_HEAD_COMMIT_HASH" -eq 1 ]] &&
      CUSTOM_LOCALVERSION+="-$(git rev-parse --short="$HEAD_COMMIT_HASH_LENGTH" HEAD)"
    printf '%s' "-$CUSTOM_LOCALVERSION" > "$KernelPath/localversion"
  fi

  export LOCALVERSION="$(
    [[ -f "$KernelPath/localversion" ]] &&
      cat "$KernelPath/localversion" ||
      sed -n 's/^CONFIG_LOCALVERSION=//p' "$DEFCONFIG_FILE"
  )"
else
  LOCALVERSION=
fi

case "$KERNEL_COMPRESSION" in
  none)
    BOOT_NAME_PREFIX=""
    KERNEL_IMAGE_NAME="Image"
    KERNEL_COMPRESSION_LEVEL=0
    KERNEL_COMPRESSION_LEVEL_NAME=""
    ;;
  gz)
    BOOT_NAME_PREFIX="-"
    KERNEL_IMAGE_NAME="Image.gz"
    KERNEL_COMPRESSION_LEVEL=1
    KERNEL_COMPRESSION_LEVEL_NAME="gz"
    ;;
  lz4)
    BOOT_NAME_PREFIX="-"
    KERNEL_IMAGE_NAME="Image.lz4"
    KERNEL_COMPRESSION_LEVEL=2
    KERNEL_COMPRESSION_LEVEL_NAME="lz4"
    ;;
  *)
    a_print lr "Kernel Compression is $KERNEL_COMPRESSION which is unknown by compiler"
    BOOT_NAME_PREFIX=""
    KERNEL_IMAGE_NAME="Image"
    KERNEL_COMPRESSION_LEVEL=0
    KERNEL_COMPRESSION_LEVEL_NAME=""
    ;;
esac

KERNEL_BOOTIMG_NAME="boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME"

if [[ "$BAZEL_BUILD" -eq 1 ]]; then
    IMAGE="${MainPath}/bazel-bin/common/kernel_aarch64/$KERNEL_IMAGE_NAME"
else
    IMAGE="${MainPath}/out/arch/arm64/boot/$KERNEL_IMAGE_NAME"
fi

getdtb() {
  if [[ "$USING_DTB" -eq 1 ]]; then
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
  elif [[ "$USING_DTB" -eq 2 ]]; then
    DTS_DIR="${MainPath}/out/arch/arm64/boot/dts/vendor/$ARCH_VENDOR"
    DTB_FILE="$DTS_DIR/$DEVICE_CODENAME.dtb"
    #DTB_FILE="${MainPath}/out/arch/arm64/boot/dtb.img"
    DTBO_FILE="${MainPath}/out/arch/arm64/boot/dtbo.img"
  else
    a_print lr "USING_DTB config is not set, skipping DTB."
  fi
}

ksu_patch

if [ "$IS_KERNELSU" != "n" ]; then
  BUILD_VARIANT="KernelSU"
  KERNEL_VARIANT_NAME="-$BUILD_VARIANT"
else
  BUILD_VARIANT="Non-KSU"
  KERNEL_VARIANT_NAME=""
fi

if [[ "$USING_BOOTIMG" -eq 1 ]]; then
  KERNEL_ZIP="${KERNEL_NAME}${KERNEL_VARIANT_NAME}-boot-${DEVICE_CODENAME}-${BUILD_DATE}.zip"
else
  KERNEL_ZIP="${KERNEL_NAME}${KERNEL_VARIANT_NAME}-${DEVICE_CODENAME}-${BUILD_DATE}.zip"
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

MAKE_ARGS=(
  -j"$CORES"
  ARCH="$ARCH"
  O=out
  CC=clang
  CLANG_TRIPLE="$CrossCompileFlagTriple"
  CROSS_COMPILE="$CrossCompileFlag64"
  CROSS_COMPILE_ARM32="$CrossCompileFlag32"
)

if [[ "$CLANG_ONLY" -eq 1 ]]; then
  MAKE_ARGS+=(
    LD=ld.lld
    LLVM=1
    LLVM_IAS=1
    AR=llvm-ar
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    STRIP=llvm-strip
  )
fi

StartMake() {
  export MSM_ARCH=$BOARD_CODENAME

  if [[ "$ENABLE_MULTICONFIG" -eq 1 ]]; then
    # make O=out ARCH=$ARCH $BASE_CONFIG

    BASE_CONFIG_PATH="${KernelPath}/arch/${ARCH}/configs/${BASE_CONFIG}"
    FRAGMENT_CONFIG_PATH="${KernelPath}/arch/${ARCH}/configs/vendor/${FRAGMENT_CONFIG}"
    if [ -f "$FRAGMENT_CONFIG_PATH" ]; then
      #a_print lb "$FRAGMENT_CONFIG fragment detected, merging!"
      MERGED_CONFIG_PATH="$KernelPath/arch/$ARCH/configs/merged_defconfig"
      awk -F= '!seen[$1]++' $BASE_CONFIG_PATH $FRAGMENT_CONFIG_PATH > $MERGED_CONFIG_PATH
      #bash scripts/kconfig/merge_config.sh -m .config $FRAGMENT_CONFIG_PATH
    else
      MERGED_CONFIG_PATH=""
      #a_print lr "$FRAGMENT_CONFIG config does not exists, abortting!"
    fi
    make O=out ARCH=$ARCH merged_defconfig
    # comment this code bellow if you want to take the merged config content
    if [ -f "$MERGED_CONFIG_PATH" ]; then
      rm -f $MERGED_CONFIG_PATH
    fi
  else
    make O=out ARCH=$ARCH $DEVICE_DEFCONFIG
  fi

  make "${MAKE_ARGS[@]}"
}

compile() {
  tgm "Kernel Compilation for $DEVICE_MODEL has been started

Kernel Name: $KERNEL_NAME
Kernel Version: $KERNELVERSION
Kernel Variant: $BUILD_VARIANT
Compiler: $KBUILD_COMPILER_STRING"

  if [[ "$BAZEL_BUILD" -eq 1 ]]; then
    tools/bazel build --config=fast --lto=thin //common:kernel_aarch64_dist
  else
    if [[ "$ClangName" = "proton" ]]; then
      sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' "$DEFCONFIG_FILE"
    else
      sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' "$DEFCONFIG_FILE"
    fi

    mkdir -p "$MainPath/out"
    [ -f "$MainPath/out/output.log" ] || touch "$MainPath/out/output.log"

    [[ "$ENABLE_OUTPUT_LOG" -eq 1 ]] && StartMake |& tee out/output.log || StartMake
  fi

  if [[ ! -f "$IMAGE" ]]; then
    timeOut=$(updateTime)
    BUILD_RESULT="❌ Compile Kernel for $DEVICE_MODEL failed, Check console log to fix it!"
    a_print lr "$BUILD_RESULT, Completed in $timeOut"
    [[ "$BAZEL_BUILD" -eq 1 ]] && tgm "$BUILD_RESULT" || tgannounce "out/output.log" "$BUILD_RESULT"
    cleanup
    exit 1
  fi

  cd "$MainPath" || exit 1

  if [[ "$USING_BOOTIMG" -eq 1 ]]; then
    a_print lg "Building $KERNEL_BOOTIMG_NAME.img"

    mkdir -p bootimgs
    cd bootimgs || exit 1

    cp "$IMAGE" "$KERNEL_IMAGE_NAME"
    GenerateBootImage

    if [[ -f "$KERNEL_BOOTIMG_NAME.img" ]]; then
      (cd "$KernelPath" && changelogs)
    else
      a_print lr "Failed to build $KERNEL_BOOTIMG_NAME, Check console log to fix it!"
    fi

    cd "$MainPath" || exit 1
  else
    cloneAK3
    cp "$IMAGE" "$AnyKernelPath"
    changelogs
  fi
}

genResultMsg() {
  BUILD_RESULT="✅ Compile Kernel for $DEVICE_MODEL successfully,

Build date: $BUILD_DATE2
Kernel Name: $KERNEL_NAME
Kernel Version: $KERNELVERSION
Kernel Variant: $BUILD_VARIANT"

  [ "$IS_KERNELSU" != "n" ] && BUILD_RESULT+="
KernelSU Manager: $KERNELSU_MANAGER"

  BUILD_RESULT+="

Completed in $timeOut

$PRINT_CHANGELOG"
}

# Zipping function
zipping() {
  if [[ "$IS_AK3_EXISTS" -eq 1 ]]; then
    if [[ "$USING_BOOTIMG" -eq 1 ]]; then
      zip -q -r9 ${KERNEL_ZIP} "boot$BOOT_NAME_PREFIX$KERNEL_COMPRESSION_LEVEL_NAME.img" "$CHANGELOG_FILE_NAME"
    else
      cd ${AnyKernelPath} || exit 1
      ak_store_script_content
      #ak_update_kernel_name
      if [ "$ENABLE_CHANGELOG" = "yes" ]; then
        if [ -f "${ChangelogPath}/$CHANGELOG_FILE_NAME" ]; then
          cp ${ChangelogPath}/$CHANGELOG_FILE_NAME ./
        fi
      fi

      getdtb

      if [ ! -z "$USING_DTB" ]; then
        if [ -f "$DTB_FILE" ]; then
          cp $DTB_FILE ${AnyKernelPath}/dtb
        fi
        if [ -f "$DTBO_FILE" ]; then
          cp $DTBO_FILE ${AnyKernelPath}/dtbo
        fi
      fi
      
      zip -q -r9 ${KERNEL_ZIP} * -x .git README.md *placeholder
    fi

    timeOut=$(updateTime)

    #upload ${KERNEL_ZIP}
    
    genResultMsg

    a_print lg  "\n=========================================="
    a_print lg  "Build completed in $timeOut"
    a_print lg  "Kernel Name: $KERNEL_NAME"
    a_print lg  "Final zip: $AnyKernelPath/$KERNEL_ZIP"
    a_print lg  "Zip size: $(du -h "$AnyKernelPath/$KERNEL_ZIP" | cut -f1)"
    a_print lg  "=========================================="

    #echo $BUILD_RESULT
    if [[ "$TELEGRAM_UPLOADFILE" -eq 1 ]]; then
      tgannounce $KERNEL_ZIP "$BUILD_RESULT"
    else
      tgm "$BUILD_RESULT"
    fi
    cd ..
    cleanup
  fi
}

# Cleanup function
cleanup() {
  cd ${MainPath}
  rm -rf $IMAGE
  if [[ "$CLEANUP" -eq 1 || $var = "--cleanup" ]]; then
    a_print lb "Cleaning up..."
    rm -rf ${AnyKernelPath}
    rm -rf out/
    a_print lg "Cleanup done."
  fi

  #restoreLocalVersionNoCheck
  git restore localversion
  ak_restore_script_content
  defconfig_restore_content
}

ctrl_c() {
  timeOut=$(updateTime)

  BUILD_RESULT="❌ Compile Kernel for $DEVICE_MODEL was interrupted!

Reason: CtrL+C detected."

if [[ "$TGM_CTRL_C_TRAP_MSG" -eq 1 ]]; then
  tgm "$BUILD_RESULT"
fi
  a_print lr "$BUILD_RESULT"
  cleanup
  exit 1
}

updateTime() {
  END=$(date +"%s")
  DIFF=$(( $END - $START ))

  hours=$((DIFF / 3600))
  minutes=$(( (DIFF % 3600) / 60 ))
  seconds=$((DIFF % 60))
  str=""

  (( hours > 0 ))   && str+="${hours}h "
  (( minutes > 0 )) && str+="${minutes}m "
  (( seconds > 0 )) && str+="${seconds}s"

  printf "%s" "$str"
}

[[ "$DIRECT_ZIPPING" -eq 0 ]] && {
  trap ctrl_c INT

  [[ "$BAZEL_BUILD" -eq 0 ]] && {
    #cloneAK3
    getclang
    updateclang
    clonegcc
  }

  getcompilerString

  case "$var" in
    -c|--clean)
      a_print lg "Cleaning up out directory..."
      rm -rf "$MainPath/out"
      a_print lg "Out directory is now cleared, ready for clean build"
      ;;
  esac

  compile
  zipping
  cleanup
} || {
  getcompilerString
  zipping
}
