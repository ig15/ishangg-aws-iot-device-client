#!/bin/sh
# Compiler name, g++ or clang, just need the first character
compilerName=$(echo $1 | cut -c12-12)
# Everything that follows the first character
compilerExec=$(echo $1 | cut -c12-20)
echo $compilerName
echo $compilerExec
if [ $# -eq 1 ]
  then
    apt-get update
    apt-get install --assume-yes software-properties-common
    # Install correct compiler from CI matrix from (APT)
    if [ $compilerName = "g" ]
      then
        # Cuts to just the version ie, g++-{7}
        ver=$(echo $compilerExec | cut -c5-20)
        echo "ver"
        echo $ver
        add-apt-repository ppa:ubuntu-toolchain-r/test -y
        apt-get update
        apt-get --assume-yes install g++-$ver

        export CXX=/usr/bin/g++-$ver
    fi
    if [ $compilerName = "c" ]
      then
        # Cuts to just the version ie, clang-{7}
        ver=$(echo $compilerExec | cut -c7-20)
        if [ $ver = "5" ] || [ $ver = "6" ]
          then
            ver=$(echo "$ver.0")
        fi
        echo "ver"
        echo $ver
        apt-get --assume-yes install apt-transport-https
        wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add
        apt-add-repository "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-$ver main" -y
        apt-get update
        apt-get --assume-yes install clang-$ver
        export CXX=/usr/bin/clang++-$ver
    fi
fi

### Compile ###
cd ..
ln -s /home/sdk-cpp-workspace ./sdk-cpp-workspace
if [ ! -d "./build" ]; then
  mkdir ./build
fi
cd ./build/

cmake ../ -DBUILD_SDK=OFF -DBUILD_TEST_DEPS=OFF
cmake --build . --target aws-iot-device-client
cmake --build . --target test-aws-iot-device-client

### Run Tests ###
./test/test-aws-iot-device-client