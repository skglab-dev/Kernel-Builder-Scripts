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

export OS_ID="$(grep '^ID=' /etc/os-release | sed 's/ID=*//g')"

function show_help() {
  echo "--ghconf      Set git user.name and user.password for local git project"
  echo "--setup       Installing the build dependencies (auto os detection)"
  echo "--setup2      Installing the build dependencies and start build (auto os detection)"
  echo "--zip         Zipping the whole anykernel folder and upload it"
  echo "--cleanup     Delete the anykernel and out folder"
  echo "-h, --help    Show this help message"
}

function set_git_user() {
  if [ "$1" = "global" ]; then # first args is global so we use second args instead
  git config --global user.name $2
  git config --global user.email $3
  echo "Set global git config user to $2 <$3>"
  else # first args is empty (mean its local) so we use first args instead
  git config user.name $1
  git config user.email $2
  echo "Set git config user to $1 <$2>"
  fi
}

function install_dependencies() {
  if [ "$OS_ID" = "ubuntu" ] || [ "$1" = "ubuntu" ]; then
    echo "Installing build dependencies for Ubuntu"
    sudo apt-get update -y
    sudo apt-get -y install repo bc bison build-essential curl ccache coreutils flex g++-multilib gcc-multilib git gnupg \
    gperf lib32z1-dev liblz4-tool libncurses5-dev libsdl1.2-dev libwxgtk3.0-gtk3-dev imagemagick lunzip lzop schedtool squashfs-tools xsltproc zip \
    zlib1g-dev perl xmlstarlet virtualenv xz-utils rr jq pngcrush lib32ncurses5-dev git-lfs libxml2 openjdk-11-jdk wget lib32readline-dev \
    libssl-dev android-sdk-libsparse-utils lld libc6-dev-i386 x11proto-core-dev libx11-dev libgl1-mesa-dev fontconfig ca-certificates cpio \
    bsdmainutils lz4 aria2 rclone ssh-client libncurses5 rsync python-is-python3 libarchive-tools python3 zstd
  else
    echo "Your operating system is $OS_ID, you may need to install the build dependencies manually"
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
. config.env
set +a

# Path
MainPath="$(readlink -f -- $(pwd))"
MainClangPath="${MainPath}/clang"
AnyKernelPath="${MainPath}/anykernel"
CrossCompileFlagTriple="aarch64-linux-gnu-"

# Clone toolchain
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
function getclang() {
  if [ "${ClangName}" = "azure" ]; then
    if [ ! -f "${MainClangPath}-azure/bin/clang" ]; then
      echo "[!] Clang is set to azure, cloning it..."
      git clone https://gitlab.com/Panchajanya1999/azure-clang clang-azure --depth=1
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      wget "https://gist.github.com/dakkshesh07/240736992abf0ea6f0ee1d8acb57a400/raw/a835c3cf8d99925ca33cec3b210ee962904c9478/patch-for-old-glibc.sh" -O patch.sh && chmod +x patch.sh && ./patch.sh
      cd ..
    else
      echo "[!] Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    if [ ! -f "${MainClangPath}-neutron/bin/clang" ]; then
      echo "[!] Clang is set to neutron, cloning it..."
      mkdir -p "${MainClangPath}"-neutron
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      curl -LOk "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
      chmod +x antman && ./antman -S
      ./antman --patch=glibc
      cd ..
    else
      echo "[!] Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "proton" ]; then
    if [ ! -f "${MainClangPath}-proton/bin/clang" ]; then
      echo "[!] Clang is set to proton, cloning it..."
      git clone https://github.com/kdrag0n/proton-clang clang-proton --depth=1
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      echo "[!] Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "zyc" ]; then
    if [ ! -f "${MainClangPath}-zyc/bin/clang" ]; then
      echo "[!] Clang is set to zyc, cloning it..."
      mkdir -p ${MainClangPath}-zyc
      cd clang-zyc
      wget $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
      tar -xf zyc-clang.tar.gz
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
      rm -f zyc-clang.tar.gz
      cd ..
    else
      echo "[!] Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "greenforce" ]; then
    if [ ! -f "${MainClangPath}-greenforce/bin/clang" ]; then
      echo "[!] Clang is set to greenforce, cloning it..."
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
      echo "[!] Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-greenforce
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  else
    echo "[!] Incorrect clang name. Check config.env for clang names."
    exit 1
  fi
  cd ${ClangPath}
  if [ ! -f 'gitignore' ] || [ ! -f '.gitignore' ]; then
    touch .gitignore
    echo "*" >> .gitignore
  elif [ -f 'gitignore' ]; then
    mv gitignore .gitignore
  fi
  if [ ! -f '/bin/clang' ]; then
    export KBUILD_COMPILER_STRING="$(${ClangPath}/bin/clang --version | head -n 1)"
  else
    export KBUILD_COMPILER_STRING="Unknown"
  fi
  cd ..
}

function updateclang() {
  [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
  if [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    echo "[!] Clang is set to neutron, checking for updates..."
    cd clang-neutron
    if [ "$(./antman -U | grep "Nothing to do")" = "" ];then
      ./antman --patch=glibc
    else
      echo "[!] No updates have been found, skipping"
    fi
    cd ..
    elif [ "${ClangName}" = "zyc" ]; then
      echo "[!] Clang is set to zyc, checking for updates..."
      cd clang-zyc
      ZycLatest="$(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt)"
      if [ "$(cat README.md | grep "Build Date : " | cut -d: -f2 | sed "s/ //g")" != "${ZycLatest}" ];then
        echo "[!] An update have been found, updating..."
        sudo rm -rf ./*
        wget $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
        tar -xf zyc-clang.tar.gz
        rm -f zyc-clang.tar.gz
      else
        echo "[!] No updates have been found, skipping..."
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
  if [ "$ENABLE_GCC64" = "yes" ];then
    git clone https://github.com/rokibhasansagar/linaro-toolchain-latest.git -b latest-7 --depth=1 gcc-64
    CrossCompileFlag64="${MainPath}/gcc-64/bin/aarch64-linux-gnu-"
  else
    CrossCompileFlag64="aarch64-linux-gnu-"
  fi
  if [ "$ENABLE_GCC32" = "yes" ]; then
    if [[ -f "${MainPath}/gcc-32" ]]; then
      mkdir gcc-32
      wget -O gcc-arm.tar.gz https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz
      tar -C gcc-32/ -zxvf gcc-arm.tar.gz
      rm -rf gcc-arm.tar.gz
    fi
    CrossCompileFlag32="${MainPath}/gcc-32/bin/arm-linux-androideabi-"
  else
    CrossCompileFlag32="arm-linux-gnueabi-"
  fi
}

# root-function
function ksu_patch() {
  if [ "$KSU_AS_MODULES" = "yes" ]; then
    sed -i "s/CONFIG_KSU=n/CONFIG_KSU=m/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
  else
    if [ "$KERNELSU" = "yes" ]; then
      sed -i "s/CONFIG_KSU=n/CONFIG_KSU=y/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
    else
      sed -i "s/CONFIG_KSU=y/CONFIG_KSU=n/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
    fi
  fi
}

function apatch_support() {
  if [ "$APATCH" = "yes" ]; then
    sed -i "s/CONFIG_APATCH_SUPPORT=n/CONFIG_APATCH_SUPPORT=y/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
  else
    sed -i "s/CONFIG_APATCH_SUPPORT=y/CONFIG_APATCH_SUPPORT=n/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
  fi
}

function root_function() {
  if [ "$KERNELSU" = "yes" ] && [ "$APATCH" = "yes" ]; then
    cd ${MainPath}
    export ROOT_METHOD="both"
    ksu_patch
    apatch_support
  fi

  if [ ! "$ROOT_METHOD" = "both" ]; then
    if [ "$KERNELSU" = "yes" ] && [ "$APATCH" = "no" ]; then
      export ROOT_METHOD="kernelsu"
      if [ ! -f "${MainPath}/KernelSU/README.md" ]; then
          cd ${MainPath}
          ksu_patch
      fi
    else
      cd ${MainPath}
      export ROOT_METHOD="apatch"
      apatch_support
    fi
  fi
}

# NetHunter enabled automaticlly when KernelSU is enabled, so don't disable it when KernelSU is enabled
function nethunter_support() {
  if [ "$NETHUNTER" = "yes" ] || [ "$KERNELSU" = "yes" ]; then
    sed -i "s/CONFIG_NETHUNTER_SUPPORT=n/CONFIG_NETHUNTER_SUPPORT=y/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
  else
    if [ "$KERNELSU" = "no" ]; then
      sed -i "s/CONFIG_NETHUNTER_SUPPORT=y/CONFIG_NETHUNTER_SUPPORT=n/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
    fi
  fi
}

function upload() {
  #if [ ! -f "/var/www/html/$1" ] then
  #  rm -rf /var/www/html/$1
  #fi
  #mv $1 /var/www/html/
  #echo "http://128.199.250.112/$1"
  curl -F "file=@$1" https://temp.sh/upload
  echo 
}

# Enviromental variable
export BUILD_TIME="$(date "+%Y%m%d")"
export SUBLEVEL="5.4.$(cat "${MainPath}/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')"
if [[ -f "${MainPath}/localversion" ]]; then
export LOCALVERSION="$(cat "${MainPath}/localversion")"
else
export LOCALVERSION=
fi
IMAGE="${MainPath}/out/arch/arm64/boot/Image"
DTB_IMAGE="${MainPath}/out/arch/arm64/boot/dts/vendor/xiaomi/stone.dtb"
DTBO_IMAGE="${MainPath}/out/arch/arm64/boot/dtbo.img"
CORES="$(nproc --all)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Start Compile
START=$(date +"%s")

compile(){
if [ "$ClangName" = "proton" ]; then
  sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' ${MainPath}/arch/$ARCH/configs/$DEVICE_DEFCONFIG || echo ""
else
  sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' ${MainPath}/arch/$ARCH/configs/$DEVICE_DEFCONFIG || echo ""
fi

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
    CROSS_COMPILE_ARM32=${CrossCompileFlag32} |& tee out/output.txt
else
make -j"$CORES" ARCH=$ARCH O=out \
    CC=clang \
    CLANG_TRIPLE=${CrossCompileFlagTriple} \
    CROSS_COMPILE=${CrossCompileFlag64} \
    CROSS_COMPILE_ARM32=${CrossCompileFlag32} |& tee out/output.txt
fi

   if [[ -f "$IMAGE" ]]; then
      cd ${MainPath}
      git clone --depth=1 ${AnyKernelRepo} -b ${AnyKernelBranch} ${AnyKernelPath}
      cp $IMAGE ${AnyKernelPath}
      if [ "$1" = "--dtb" ]; then
        if [[ -f "$DTB_IMAGE" ]]; then
          cp $DTB_IMAGE ${AnyKernelPath}/dtb
        fi
        if [[ -f "$DTBO_IMAGE" ]]; then
          cp $DTBO_IMAGE ${AnyKernelPath}/dtbo
        fi
      fi
      echo "✅ Compile Kernel for $DEVICE_MODEL successfully, Kernel version: $SUBLEVEL$LOCALVERSION"
   else
      echo "❌ Compile Kernel for $DEVICE_MODEL failed, Check console log to fix it!"
      if [ "$CLEANUP" = "yes" ];then
        cleanup
      fi
      exit 1
   fi
}

KERNEL_ZIP="${KERNEL_NAME}-${DEVICE_CODENAME}-${BUILD_TIME}.zip"

# Zipping function
function zipping() {
    cd ${AnyKernelPath} || exit 1
    zip -r9 ${KERNEL_ZIP} * -x .git README.md *placeholder
    upload ${KERNEL_ZIP}
    cd ..
    cleanup
}

# Cleanup function
function cleanup() {
    cd ${MainPath}
    rm -rf $IMAGE
    if [ "$CLEANUP" = "yes" ] || [ "$1" = "--cleanup" ]; then
      rm -rf ${AnyKernelPath}
      rm -rf out/
    fi
}


if [ "$1" = "--zip" ] || [ "$1" = "--zipping" ]; then
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
else
getclang
updateclang
if [ "$CLANG_ONLY" = "no" ]; then
clonegcc
fi
root_function
nethunter_support
compile
zipping
cleanup
END=$(date +"%s")
DIFF=$(($END - $START))
fi
fi
