#!/bin/bash


# export PLATFORM_VERSION=13
# export ANDROID_MAJOR_VERSION=t
# export ARCH=arm64

# make clean && make mrproper
# make ARCH=arm64 mizkernel-a12snsxx_defconfig
# make ARCH=arm64 -j64


# Help

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then 
    echo "MizKernel Builderscript"
    echo "Ported for REKERNEL Edition"
    echo ""
    echo "./build.sh [ARGS(ANY)]"
    echo ""
    echo "Args:"
    echo "Help       -h/--help"
    echo "LTO"
    echo "   FULL    --lto=full"
    echo "   THIN    --lto=thin"
    echo "   NONE    --lto=null"
    echo "LLD"
    echo "   LLD ON  --lld=on"
    echo "   LLD OFF --lld=off"
    echo "Not arg with LLD, disables LLD by default"
    echo "Git Submodule fetch"
    echo "   Git submodule on  --gs=on"
    echo "   Git submodule off --gs=off"
    exit 1
fi

function help() {
    echo "MizKernel Builderscript"
    echo "Ported for REKERNEL Edition"
    echo ""
    echo "./build.sh [ARGS(ANY)]"
    echo ""
    echo "Args:"
    echo "Help       -h/--help"
    echo "LTO"
    echo "   FULL    --lto=full"
    echo "   THIN    --lto=thin"
    echo "   NONE    --lto=null"
    echo "LLD"
    echo "   LLD ON  --lld=on"
    echo "   LLD OFF --lld=off"
    echo "Not arg with LLD, disables LLD by default"
    echo "Git Submodule fetch"
    echo "   Git submodule on  --gs=on"
    echo "   Git submodule off --gs=off"
    exit
}


# Check if theres no arg


if [ -z "$1" ]; then
    help
fi


# Note:
# Force the make to have it 64 threads because Github allows it

export KBUILD_BUILD_USER="@Mizumo_prjkt"
export KBUILD_BUILD_HOST="MizProject (MIZPRJKT)"
export LLVM=1

wipe_old_conf() {
    rm -rf .config
    rm -rf .config.old
}

# Summon KSU and some toolchains

if [ "$3" == "--gs=on" ]; then
git-init_() {
    git submodule init && git submodule update
}
else
    echo "Submodule init and update off"
fi

build() {
    export PLATFORM_VERSION=13
    export ANDROID_MAJOR_VERSION=t
    export ARCH=arm64

    # Additional Features
    # xxARG is fallback because for some reason it doesnt acknowledge the fact that it needs LTO or LLD or not
    if [ "$1" == "--lto=full" ]; then
        export LTO=full
        LTOARG="LTO=full"
    elif [ "$1" == "--lto=thin" ]; then
        export LTO=thin
        LTOARG="LTO=thin"
    elif [ "$1" == "--lto=null" ]; then
        echo "NLTO"
        LTOARG=" "
    fi


    if [ "$2" == "--lld=on" ]; then
        export LD="ld.lld"
        LDARG="LD=ld.lld"
    elif [ "$2" == "--lld=off" ]; then
        LDARG=" "
    else 
        LDARG=" "
    fi

    
    make clean && make mrproper
    make -j64 KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y ARCH=arm64 mizproject/mizkernel-a12snsxx_defconfig $LTOARG $LDARG
    make -j64 KCFLAGS=-w CONFIG_SECTION_MISMATCH_WARN_ONLY=y ARCH=arm64 
    cp out/arch/arm64/boot/Image $(pwd)/arch/arm64/boot/Image
}

START_BUILD_TIME_RAW=$(TZ="Asia/Manila" date +%T)
START_BUILD_DATE_RAW=$(TZ="Asia/Manila" date +%F)
START_BUILD_TIME_AND_DATE="$START_BUILD_TIME_RAW - $START_BUILD_DATE_RAW"
echo "Starting Compile of A12s Kernel"
echo "Start Build: $START_BUILD_TIME_AND_DATE"

wipe_old_conf
if [ "$3" == "--gs=on" ]; then
git-init_
fi
build

echo "Build Ended :D"
END_BUILD_TIME_RAW=$(TZ="Asia/Manila" date +%T)
END_BUILD_DATE_RAW=$(TZ="Asia/Manila" date +%F)
END_BUILD_TIME_AND_DATE="$END_BUILD_TIME_RAW - $END_BUILD_DATE_RAW"
echo "Build Ended: $END_BUILD_TIME_AND_DATE"

