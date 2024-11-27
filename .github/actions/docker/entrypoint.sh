#!/bin/sh -l

# ubuntu dockerfile is very minimal (only 122 packages are installed)
# need to install updated git (from official git ppa)
apt update
apt install -y software-properties-common
add-apt-repository ppa:git-core/ppa -y
# install dependencies expected by other steps
apt update
apt install -y git \
curl \
ca-certificates \
wget \
bzip2 \
zip \
unzip \
xz-utils \
openjdk-11-jdk-headless \
maven \
build-essential \
ant \
sudo \
locales
# set Locale to en_US.UTF-8 (avoids hang during compilation)
locale-gen en_US.UTF-8
echo "LANG=en_US.UTF-8" >> $GITHUB_ENV
echo "LANGUAGE=en_US.UTF-8" >> $GITHUB_ENV
echo "LC_ALL=en_US.UTF-8" >> $GITHUB_ENV

sudo sed -i 's/deb http/deb [arch=amd64,i386] http/' /etc/apt/sources.list
grep "ubuntu.com/ubuntu" /etc/apt/sources.list | sudo tee /etc/apt/sources.list.d/ports.list
sudo sed -i 's/amd64,i386/armhf,arm64/' /etc/apt/sources.list.d/ports.list
sudo sed -i 's#http://.*/ubuntu#http://ports.ubuntu.com/ubuntu-ports#' /etc/apt/sources.list.d/ports.list
# Add extra platform architectures
sudo dpkg --add-architecture i386; sudo dpkg --add-architecture armhf; sudo dpkg --add-architecture arm64
sudo apt-get update
# Install Windows compilers
sudo apt-get -yq install g++-mingw-w64-i686 g++-mingw-w64-x86-64
# Install Linux x86 compilers/libraries
sudo apt-get -yq install gcc-multilib g++-multilib linux-libc-dev:i386
# Install Linux arm32 compilers/libraries
sudo apt-get -yq install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf
# Install Linux arm64 compilers/libraries
sudo apt-get -yq install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu

find -type f -path "SDL/*.h" -exec sed -i 's/extern DECLSPEC//' {} \;
sed -i 's/#define SDL_DYNAMIC_API 1/#define SDL_DYNAMIC_API 0/' SDL/src/dynapi/SDL_dynapi.h

mkdir -p SDL/build-linux64
cd SDL/build-linux64
../configure CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd -

mkdir -p SDL/build-linux32
cd SDL/build-linux32
../configure CFLAGS="-fPIC -m32" CPPFLAGS="-fPIC -m32" LDFLAGS="-m32" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd -

mkdir -p SDL/build-linuxarm32
cd SDL/build-linuxarm32
../configure --host=arm-linux-gnueabihf CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd -

mkdir -p SDL/build-linuxarm64
cd SDL/build-linuxarm64
../configure --host=aarch64-linux-gnu CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
run: make -j
cd -

mkdir -p SDL/build-windows32
cd SDL/build-windows32
../configure --host=i686-w64-mingw32 --disable-audio --disable-render --disable-power --disable-filesystem --disable-hidapi
run: make -j
cd -

mkdir -p SDL/build-windows64
cd SDL/build-windows64
./configure --host=x86_64-w64-mingw32 --disable-audio --disable-render --disable-power --disable-filesystem --disable-hidapi
run: make -j
cd -

chmod +x gradlew
./gradlew jnigen jnigenBuild jnigenJarNativesDesktop