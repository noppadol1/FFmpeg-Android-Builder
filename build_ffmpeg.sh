#!/bin/bash

# 1. ตั้งค่าตัวแปรเบื้องต้น
FFMPEG_VERSION="7.0"
NDK_PATH=$ANDROID_NDK_LATEST_HOME # GitHub Actions มี NDK ให้อยู่แล้ว
TOOLCHAIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64
API_LEVEL=21

# ดาวน์โหลด FFmpeg Source Code
wget https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
tar xjvf ffmpeg-$FFMPEG_VERSION.tar.bz2
cd ffmpeg-$FFMPEG_VERSION

function build_ffmpeg {
    ABI=$1
    ARCH=$2
    CROSS_PREFIX=$3
    OUTPUT_PATH=$(pwd)/android/$ABI

    echo "Building for $ABI..."

    ./configure \
        --prefix=$OUTPUT_PATH \
        --enable-shared \
        --disable-static \
        --enable-pic \
        --disable-doc \
        --disable-ffmpeg \
        --disable-ffplay \
        --disable-ffprobe \
        --disable-avdevice \
        --disable-symver \
        --cross-prefix=$CROSS_PREFIX \
        --target-os=android \
        --arch=$ARCH \
        --enable-cross-compile \
        --sysroot=$TOOLCHAIN/sysroot \
        --extra-cflags="-Os -fpic" \
        --cc=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}-clang \
        --cxx=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}-clang++ \
        --nm=$TOOLCHAIN/bin/llvm-nm \
        --ar=$TOOLCHAIN/bin/llvm-ar \
        --as=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}-clang \
        --strip=$TOOLCHAIN/bin/llvm-strip \
        --ranlib=$TOOLCHAIN/bin/llvm-ranlib \
        --enable-neon \
        --enable-hwaccels \
        --enable-gpl \
        --disable-everything \
        --enable-decoder=h264,aac,mp3,mpeg4 \
        --enable-encoder=aac,mpeg4 \
        --enable-parser=h264,aac,mpegaudio \
        --enable-demuxer=mov,mp4,m4a,mp3,wav,avi,matroska \
        --enable-muxer=mp4,mov,mp3,wav \
        --enable-protocol=file \
        --enable-filter=trim,atrim,amix,volume,aresample,scale

    make clean
    make -j$(nproc)
    make install
}

# รันการ Build สำหรับสถาปัตยกรรมต่างๆ
build_ffmpeg "arm64-v8a" "aarch64" "aarch64-linux-android"
build_ffmpeg "armeabi-v7a" "arm" "armv7a-linux-androideabi"

echo "Build Completed! Files are in $(pwd)/android"
