#!/bin/bash

# http://chtaube.eu/computers/freedos/bootable-usb/image-generation-howto/

#syslinux – Bootloader
#GNU parted – Other partitioning tools did not yield a bootable image.
#mkfs.msdos (or mkdosfs) – Debian and Arch Linux users can install the dosfstools package
#kpartx – A tool for mounting partitions within an image file; Debian has this in the kpartx package; For Arch Linux the multipath-tools from AUR look promising.
#The FreeDOS distribution ISO: fd11src.iso (or look here for the latest release: http://www.freedos.org/download/)
#Some smaller utilities everyone should have: dd, unzip, find, xargs

dd if=/dev/zero of=FreeDOS-image.img bs=1M count=30

#Next, we use parted to put a partition table into this file and mark it bootable:
parted FreeDOS-image.img
#(parted) unit %
#(parted) mklabel msdos
#(parted) mkpart primary fat16 0 100%
#(parted) set 1 boot on
#(parted) p

#Now, we have an image file with a valid partition table. But we need access to the partition within the file. kpartx is our friend here:

kpartx -av FreeDOS-image.img

#Make a FAT16 filesystem with the volume label set to "FREEDOS":

mkfs.msdos -F 16 -n FREEDOS /dev/mapper/loop2p1

#Install the syslinux bootloader:

syslinux -i /dev/mapper/loop2p1

#With the FAT16 filesystem written, we can mount the image file to put the remaining files on it:

mkdir ~/fdos/memdisk
mount /dev/mapper/loop2p1 ~/fdos/memdisk


#Now we need access to the installation files from the FreeDOS installation CD. I didn't burn a CD from the ISO image but mount it directly from the fd11src.iso-file:

mkdir ~/fdos/freedos
mount -o ro,loop fd11src.iso ~/fdos/freedos

#Unpack the programs from the FreeDOS base package to a temporary location:

find ~/fdos/freedos/freedos/packages/base/*.zip | xargs -l unzip -d ~/fdos/temp/

#We need chain.c32 from the syslinux package:

unzip -d ~/fdos/temp2/ ~/fdos/freedos/freedos/packages/boot/syslnxx.zip
cp ~/fdos/temp2/bin/chain.c32 ~/fdos/memdisk/fdos/

#Copy all files from the bin-directory onto the image.

cp -R ~/fdos/temp/{bin,BIN}/* ~/fdos/memdisk/fdos/

#Syslinux needs a configuration file for booting FreeDOS.

#Write it to ~/fdos/memdisk/syslinux.cfg:

syslinux.cfg

default fdos
prompt 1
timeout 3
say -
say Welcome to FreeDOS 1.1 bootable USB flash drive!
say Created by Christian Taube 
say http://chtaube.eu/computers/freedos/bootable-usb/
say http://chtau.be/freedosusb

label fdos
    menu label fdos - Load FreeDOS 1.1 from USB flash drive
    com32 /fdos/chain.c32
    append freedos=/fdos/kernel.sys

#FreeDOS has its own set of configuration files for loading drivers, setting up the keyboard and all this stuff. 
#There are some reasonable defaults included within the FreeDOS distribution but the paths do not match our directory structure. 
#You may wish to copy my modified versions from below to ~/fdos/memdisk/config.sys and ~/fdos/memdisk/autoexec.bat:

config.sys

!COUNTRY=001,437,C:\FDOS\COUNTRY.SYS 
!LASTDRIVE=Z
!BUFFERS=20
!FILES=40
!DOSDATA=UMB
!MENUCOLOR=7,0
MENUDEFAULT=1,5
MENU 1 - Load FreeDOS with JEMMEX, no EMS (most UMBs), max RAM free
MENU 2 - Load FreeDOS with EMM386+EMS and SHARE
MENU 3 - Load FreeDOS including HIMEMX XMS-memory driver
MENU 4 - Load FreeDOS without drivers 
1?DEVICE=C:\FDOS\JEMMEX.EXE NOEMS X=TEST 
3?DEVICE=C:\FDOS\HIMEMX.EXE 
2?DEVICE=C:\FDOS\JEMMEX.EXE X=TEST I=B000-B7FF
12?DOS=HIGH
12?DOS=UMB
1234?SHELLHIGH=C:\FDOS\COMMAND.COM C:\FDOS /E:1024 /P=C:\AUTOEXEC.BAT
1234?SET DOSDIR=C:\FDOS

autoexec.bat

@echo off 
set lang=EN
set PATH=%dosdir%
set NLSPATH=%dosdir%
set HELPPATH=%dosdir%
set temp=%dosdir%
set tmp=%dosdir%
SET BLASTER=A220 I5 D1 H5 P330
set DIRCMD=/P /OGN
if "%config%"=="4" goto end
lh doslfn 
SHSUCDX /QQ /D3
IF EXIST FDBOOTCD.ISO LH SHSUCDHD /Q /F:FDBOOTCD.ISO
LH FDAPM APMDOS
if "%config%"=="2" LH SHARE
REM LH DISPLAY CON=(EGA,,1)
REM NLSFUNC C:\FDOS\COUNTRY.SYS
REM MODE CON CP PREP=((858) A:\cpi\EGA.CPX)
REM MODE CON CP SEL=858
REM CHCP 858
REM LH KEYB US,,C:\FDOS\KEY\US.KL  
DEVLOAD /H /Q %dosdir%\uide.sys /D:FDCD0001 /S5
ShsuCDX /QQ /~ /D:?SHSU-CDH /D:?FDCD0001 /D:?FDCD0002 /D:?FDCD0003
mem /c /n
shsucdx /D
goto end
:end
SET autofile=C:\autoexec.bat
SET CFGFILE=C:\config.sys
alias reboot=fdapm warmboot
alias halt=fdapm poweroff
echo type HELP to get support on commands and navigation
echo.
echo Welcome to FreeDOS 1.1
echo

#Unmount the disk image:

umount ~/fdos/memdisk

#Unmount the FreeDOS installation CD:

umount ~/fdos/freedos

#Clean up the temporary directories:

rm -rf ~/fdos/temp
rm -rf ~/fdos/temp2

#You are done! The image file FreeDOS-image.img is ready to be used now!


