# https://github.com/envoyproxy/envoy/issues/23339
# https://learn.arm.com/learning-paths/servers-and-cloud-computing/envoy/build_install_envoy/
# Raspberry Pi OS requires a compiler flag to be set
# --define tcmalloc=gperftools

sudo wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
sudo chmod +x /usr/local/bin/bazel
sudo apt update
sudo apt-get install autoconf curl libtool patch python3-pip unzip git virtualenv

pushd ~/
wget https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.1/clang+llvm-17.0.1-aarch64-linux-gnu.tar.xz
tar -xvf clang+llvm-17.0.1-aarch64-linux-gnu.tar.xz
git clone https://github.com/envoyproxy/envoy.git
cd envoy
bazel/setup_clang.sh ~/clang+llvm-17.0.1-aarch64-linux-gnu
echo "build --config=clang --define tcmalloc=gperftools" >> user.bazelrc
bazel build -c opt envoy.stripped --jobs=$(nproc)
popd