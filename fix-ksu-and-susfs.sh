#!/bin/bash

# DEBUG
# set -x

# This script helps repatching the KSU and susfs
# Developed for MizProject Kernel Development

# MizProject Philippines
# License: GPL 3

# Check if we are in the correct location
if [ ! -e "$(pwd)/build.sh" ] && [! -e "$(pwd)/Makefile"] && [ ! -d "$(pwd)/root" ] && [ ! -d "$(pwd)/root/nxtKSU"] && [ ! -d "$(pwd)/root/rKSU" ]; then
    echo "Not in predetermined directory"
    exit 1
fi

if [ ! -e "/usr/bin/dialog" ]; then
    echo "No dialog exec found"
    exit 1
fi

# Core
ROOTDIR="$(pwd)/root"

# KernelSU
RISSU_KSU="$ROOTDIR/rKSU"
NXT_KSU="$ROOTDIR/nxtKSU"

# KernelSU-Rissu Symlink
FROM_RKSU="$RISSU_KSU/kernel"

# KernelSU-NXT Symlink
FROM_NXTKSU="$NXT_KSU/kernel"

# Target Driver Link
TARGET_SYMLINK="$(pwd)/drivers/kernelsu"

# SUSFS
# 1.5.5
SUSFS="$ROOTDIR/susfs"
SUSFS_PATCH_ADD_4_19="$SUSFS/kernel_patches/50_add_susfs_in_kernel-4.10.patch"
SUSFS_ENABLE_SUSFS_FOR_KSU="$SUSFS/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch"
SUSFS_FILES_4_19_FS=("$SUSFS/kernel_patches/fs/sus_su.c" "$SUSFS/kernel_patches/fs/susfs.c")
SUSFS_FILES_4_19_INCL_LINUX=("$SUSFS/include/linux/susfs.h" "$SUSFS/include/linux/sus_su.h" "$SUSFS/include/linux/susfs_def.h")
# SUSFS-2.0
# Rissu has informed me that Backporting SuSFS to 4.19 works
# Also note that do not trigger susfs for ksu on Rissu's kernelSU, as they provided
# a branch with susfs support
SUSFS_PATCH_ADD_2_0="$SUSFS/kernel_patches/50_add_susfs_in_gki-android16-6.12.patch"
SUSFS_ENABLE_SUSFS_2_0_FOR_KSU="$SUSFS/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch"
SUSFS_FILES_2_0_FS=("$SUSFS/kernel_patches/fs/susfs.c")
SUSFS_FILES_2_0_INCL_LINUX=("$SUSFS/include/linux/susfs.h" "$SUSFS/include/linux/susfs_def.h")

# Functions

function _clear() {
    clear
}

function infobox() {
    if [ -z "$3" ] && [ -z "$4" ]; then
        VT="0"
        HT="0"
    else 
        VT="$3"
        HT="$4"
    fi
    dialog --title "$1" --infobox "$2" $VT $HT
}

function yesno() {
    if [ -z "$5" ] && [ -z "$6" ]; then
        VT="0"
        HT="0"
    else 
        VT="$5"
        HT="$6"
    fi
    # As per dialog's instructions, prioritize the label modifications first
    # Then the content, idk why they do that tbh, but that's how the man says
    dialog --yes-label "$3" --no-label "$4" --title "$1" --yesno "$2" $VT $HT
}

function msgbx() {
    if [ -z "$3" ] && [ -z "$4" ]; then
        VT="0"
        HT="0"
    else 
        VT="$3"
        HT="$4"
    fi
    dialog --title "$1" --msgbox "$2" $VT $HT
}

function splash() {
    infobox "Welcome" "Please wait"   
}

function __copy_files() {
    case "$1" in
        "SUSFS 1.5.5")
            ;;
        "SUSFS LATEST")
            ;;
    esac
}

function fix_symlink() {
    if [ "$1" == "rKSU" ]; then
        KERNELSUROOT="$RISSU_KSU/kernel"
    elif [ "$1" == "nxtKSU" ]; then
        KERNELSUROOT="$NXT_KSU/kernel"
    else 
        echo "Empty parameter"
        sleep 5
        break
    fi
    local KERNEL_ROOT="$(pwd)"
    local drivers="/drivers"
    local drivers_gki=""
    rm -rf $KERNEL_ROOT$drivers/kernelsu
    ln -sf "$KERNELSUROOT" "$KERNEL_ROOT$drivers/kernelsu"
}

function symlink_driver_detect_probe() {
    local KERNEL_ROOT="$(pwd)"
    local drivers="/drivers"
    local drivers_gki=""
    if [ ! -e "$KERNEL_ROOT$drivers/kernelsu" ]; then 
        SYMRESULT="No symbolic link detected"
        break
    fi
    if [ -e "/usr/bin/realpath" ]; then
        SYMRESULT="Detected symlink with realpath call\n\n$(realpath $KERNEL_ROOT$drivers/kernelsu)"
    elif [ -e "/usr/bin/readlink" ]; then
        # If realpath does not exist, use other
        SYMRESULT="Detected symlink with readlink call\n\n$(readlink -f $KERNEL_ROOT$drivers/kernelsu)"
    else 
        SYMRESULT="Symlink was detected, but can't determine"
    fi
}

function fix_symlink_interactive() {
    symlink_driver_detect_probe
    SYML=$(dialog \
            --backtitle "Fix KSU Symlink" \
            --title "Fix KernelSU Symlinks" \
            --menu "Fix/Set KernelSU Symlinks\n\nThis tool utilizes symlink fixing since not all hardware has the same path structure, or you just want to switch to the other KSU package. (So far, only we support KernelSU by Rissu and KernelSU Next)\n\nCurrent Symlink Status (Reported by symlink_driver_detect_probe):\n$SYMRESULT \n\nAlso after doing this, please check the drivers/Kconfig and drivers/Makefile and add/remove KernelSU as obj and Source\n\nIf the path shows <ROOT>/drivers/kernelsu, then that means its unlinked, and deleted, the realpath seems to be bugged and i am not sure why."  0 0 0 \
            "Fix/Set KSU with RKSU" "Set/Fix Rissu's KernelSU" \
            "Fix/Set KSU with NXTKSU" "Set/Fix Rifsxd KernelSU"\
            "Reset Symlink" "Delete Symlink path" \
            2>&1 >/dev/tty);
        local extvar=$?
        case $extvar in
            1)
                mainmenu
                ;;
        esac
        case $SYML in
            "Fix/Set KSU with RKSU")
                infobox "" "Rissu's KernelSU Chosen"
                sleep 2
                fix_symlink "rKSU"
                unset SYMRESULT
                fix_symlink_interactive
                ;;
            "Fix/Set KSU with NXTKSU")
                infobox "" "Rifsxd's KernelSU chosen"
                sleep 2
                fix_symlink "nxtKSU"
                unset SYMRESULT
                fix_symlink_interactive
                ;;
            "Reset Symlink")
                infobox "" "KernelSU Symlinks reset"
                unset SYMRESULT
                sleep 2
                reset_symlink
                fix_symlink_interactive
                ;;
        esac
}

function reset_symlink() {
    local KERNEL_ROOT="$(pwd)"
    local drivers="/drivers"
    local drivers_gki=""
    rm -rf $KERNEL_ROOT$drivers/kernelsu
    # Enable this line of code, if persists
    rm -rf "$(pwd)/drivers/kernelsu"
}

function comingsoon() {
    msgbx "Coming soon" "Some features are not implemented yet, but hoping in the near future, its up...\n\n - KernelSU Patching with GKI Kernel\n - KernelSU with older kernels\n - SuSFS and KSU repository update"
    mainmenu
}


function mainmenu() {
    MM=$(dialog \
            --backtitle "MizKernel Utils 2026" \
            --title "Patch Kernel with SUSFS Utility" \
            --menu "Select what action you will perform" 0 0 0 \
            "Patch/Update SuSFS" "Patch kernel with susfs" \
            "Patch KernelSU (4.19) - Samsung" "Patch kernel with KernelSU (SAMSUNG)" \
            "Fix Symlink" "Fix KernelSU Symlinks"\
            "Coming Soon" "Coming soon" \
            "Exit" "Exit Process" \
            2>&1 >/dev/tty)
    local exvar=$?
    case $exvar in
        1)
            exit
            ;;
    esac
    case $MM in
        "Coming Soon")
            comingsoon
            ;;
        "Fix Symlink")
            fix_symlink_interactive
            ;;
    esac
}

function main() {
    splash
    sleep 2
    mainmenu
}



main
