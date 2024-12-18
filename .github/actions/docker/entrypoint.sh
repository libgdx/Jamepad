#!/bin/sh -l

# ubuntu dockerfile is very minimal (only 122 packages are installed)
# need to install updated git (from official git ppa)
apt-get -q update
apt-get -yq install software-properties-common
add-apt-repository -y ppa:git-core/ppa
# install dependencies expected by other steps
apt-get -q update
apt-get -yq install git \
curl \
ca-certificates \
wget \
bzip2 \
zip \
unzip \
xz-utils \
build-essential \
sudo \
locales \
gnupg rename
#openjdk-11-jdk-headless \


# set Locale to en_US.UTF-8 (avoids hang during compilation)
locale-gen en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# add zulu apt repository - https://docs.azul.com/core/install/debian
curl -s https://repos.azul.com/azul-repo.key | gpg --dearmor -o /usr/share/keyrings/azul.gpg
echo "deb [signed-by=/usr/share/keyrings/azul.gpg] https://repos.azul.com/zulu/deb stable main" | tee /etc/apt/sources.list.d/zulu.list

# default Ubuntu jammy archive doesn't support armhf or arm64
# so remove those architectures in this list to avoid invalid URL errors
sed -i 's/deb http/deb [arch=amd64,i386] http/' /etc/apt/sources.list
# make a copy of sources.list that we'll use for armhf and arm64 ports
grep "ubuntu.com/ubuntu" /etc/apt/sources.list | tee /etc/apt/sources.list.d/ports.list
sed -i 's/amd64,i386/armhf,arm64/' /etc/apt/sources.list.d/ports.list
# change URLs in ports.list to use Ubuntu ports repo
sed -i 's#http://.*/ubuntu#http://ports.ubuntu.com/ubuntu-ports#' /etc/apt/sources.list.d/ports.list
# Add extra platform architectures
dpkg --add-architecture i386; dpkg --add-architecture armhf; dpkg --add-architecture arm64
apt-get -q update

# install zulu and java build tools
apt-get -yq install zulu8-jdk-headless maven ant

# Install Windows compilers
apt-get -yq install g++-mingw-w64-i686 g++-mingw-w64-x86-64
# Install Linux x86 compilers/libraries
apt-get -yq install gcc-multilib g++-multilib linux-libc-dev:i386
# Install Linux arm32 compilers/libraries
apt-get -yq install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf binutils-arm-linux-gnueabihf
# Install Linux arm64 compilers/libraries
apt-get -yq install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu binutils-aarch64-linux-gnu

find . -type f -path "SDL/*.h" -exec sed -i 's/extern DECLSPEC//' {} \;
sed -i 's/#define SDL_DYNAMIC_API 1/#define SDL_DYNAMIC_API 0/' SDL/src/dynapi/SDL_dynapi.h

mkdir -p SDL/build-linux64
cd SDL/build-linux64 || exit
../configure CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd - || exit

mkdir -p SDL/build-linux32
cd SDL/build-linux32 || exit
../configure CFLAGS="-fPIC -m32" CPPFLAGS="-fPIC -m32" LDFLAGS="-m32" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd - || exit

mkdir -p SDL/build-linuxarm32
cd SDL/build-linuxarm32 || exit
../configure --host=arm-linux-gnueabihf CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd - || exit

mkdir -p SDL/build-linuxarm64
cd SDL/build-linuxarm64 || exit
../configure --host=aarch64-linux-gnu CFLAGS="-fPIC" CPPFLAGS="-fPIC" --disable-audio --disable-video --disable-video-vulkan --disable-render --disable-filesystem --disable-threads --disable-directx --disable-mmx --disable-3dnow --disable-sse --disable-sse2 --disable-sse3 --disable-cpuinfo --disable-sensor --enable-hidapi
make -j
cd - || exit

mkdir -p SDL/build-windows32
cd SDL/build-windows32 || exit
../configure --host=i686-w64-mingw32 --disable-audio --disable-render --disable-power --disable-filesystem --disable-hidapi
make -j
cd - || exit

mkdir -p SDL/build-windows64
cd SDL/build-windows64 || exit
../configure --host=x86_64-w64-mingw32 --disable-audio --disable-render --disable-power --disable-filesystem --disable-hidapi
make -j
cd - || exit

# Grant execute permission for gradlew
chmod +x gradlew
# Build with Gradle
./gradlew jnigen jnigenBuild jnigenJarNativesDesktop --no-daemon

# fix built jars being of the form workspace-*.jar instead of Jamepad-*.jar
# due to the directory being mounted to /github/workspace on the container
rename 's/workspace/Jamepad/' build/libs/*

# clean up gradle files before handing back to runner
rm -rf .gradle