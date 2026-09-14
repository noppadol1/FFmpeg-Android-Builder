#!/bin/bash

FFMPEG_VERSION="7.0"
LAME_VERSION="3.100"
NDK_PATH=$ANDROID_NDK_LATEST_HOME
TOOLCHAIN=$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64
API_LEVEL=21

mkdir -p build && cd build
WORKING_DIR=$(pwd)

# Download sources
wget -q https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2
wget -q -O lame.tar.gz https://downloads.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz
git clone --depth 1 https://code.videolan.org/videolan/x264.git

tar xjf ffmpeg-$FFMPEG_VERSION.tar.bz2
tar xzf lame.tar.gz

function build_one {
    ABI=$1
    ARCH=$2
    CROSS_PREFIX=$3
    OUTPUT_PATH=$WORKING_DIR/output/$ABI

    echo "--- Building $ABI ---"
    mkdir -p $OUTPUT_PATH

    # 1. Build LAME
    cd $WORKING_DIR/lame-$LAME_VERSION
    ./configure \
        --host=$CROSS_PREFIX \
        --prefix=$OUTPUT_PATH \
        --disable-static \
        --enable-shared \
        CC=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}-clang \
        CFLAGS="-fPIC"
    make clean && make -j$(nproc) && make install

    # 2. Build x264
    cd $WORKING_DIR/x264
    ./configure \
        --host=$CROSS_PREFIX \
        --prefix=$OUTPUT_PATH \
        --enable-shared \
        --disable-cli \
        --cross-prefix=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}- \
        --sysroot=$TOOLCHAIN/sysroot \
        --extra-cflags="-fPIC"
    make clean && make -j$(nproc) && make install

    # 3. Build FFmpeg
    cd $WORKING_DIR/ffmpeg-$FFMPEG_VERSION
    ./configure \
        --prefix=$OUTPUT_PATH \
        --enable-shared \
        --disable-static \
        --enable-pic \
        --disable-doc \
        --disable-ffmpeg \
        --cross-prefix=$TOOLCHAIN/bin/$CROSS_PREFIX$API_LEVEL- \
        --target-os=android \
        --arch=$ARCH \
        --enable-cross-compile \
        --sysroot=$TOOLCHAIN/sysroot \
        --cc=$TOOLCHAIN/bin/${CROSS_PREFIX}${API_LEVEL}-clang \
        --nm=$TOOLCHAIN/bin/llvm-nm \
        --ar=$TOOLCHAIN/bin/llvm-ar \
        --extra-cflags="-I$OUTPUT_PATH/include" \
        --extra-ldflags="-L$OUTPUT_PATH/lib" \
        --enable-gpl \
        --enable-libmp3lame \
        --enable-libx264 \
        --disable-everything \
        --enable-decoder=h264,aac,mp3,mpeg4,mjpeg,png \
        --enable-encoder=aac,mpeg4,libmp3lame,libx264,mjpeg,png \
        --enable-parser=h264,aac,mpegaudio \
        --enable-demuxer=mov,mp4,m4a,mp3,wav,avi,matroska,image2,mjpeg,png \
        --enable-muxer=mp4,mov,mp3,wav,ipod,image2 \
        --enable-protocol=file \
        --enable-filter=trim,atrim,amix,volume,aresample,scale,fps,format,anull,aformat

    make clean && make -j$(nproc) && make install
}

build_one "arm64-v8a" "aarch64" "aarch64-linux-android"
build_one "armeabi-v7a" "arm" "armv7a-linux-androideabi"

echo "ALL DONE!"
