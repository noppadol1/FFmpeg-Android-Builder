#!/bin/bash

# 1. ตัวแปรพื้นฐาน
FFMPEG_VERSION="7.0"
NDK_PATH=$ANDROID_NDK_LATEST_HOME 
TOOLCHAIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64
API_LEVEL=21

# ดาวน์โหลด Source
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
        --enable-jni \
        --enable-mediacodec \
        --disable-everything \
        --enable-decoder=h264,aac,mp3,png,mjpeg \
        --enable-encoder=aac,h264_mediacodec \
        --enable-parser=h264,aac,mpegaudio \
        --enable-demuxer=mov,mp4,m4a,mp3,image2 \
        --enable-muxer=mp4,mov,image2 \
        --enable-protocol=file,pipe \
        --enable-filter=trim,atrim,amix,volume,aresample,scale,overlay,movie,format,aformat

    make clean
    make -j$(nproc)
    make install
}

# รันการ Build เฉพาะ 2 สถาปัตยกรรมหลักของ Android
build_ffmpeg "arm64-v8a" "aarch64" "aarch64-linux-android"
build_ffmpeg "armeabi-v7a" "arm" "armv7a-linux-androideabi"

echo "Build Completed!"CCESSFULLY!"
