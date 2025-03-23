# Based on https://github.com/envoyproxy/envoy/issues/23339#issuecomment-1987368190

# Set up environment for glibc 2.36 (Raspberry Pi OS)
FROM debian:bookworm

# Install bazel
RUN apt update
RUN apt-get install -y autoconf curl libtool patch python3-pip unzip git virtualenv wget
RUN wget -O /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-$([ $(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
RUN chmod +x /usr/local/bin/bazel

# Switch user to Bazel doesn't complain
RUN useradd -m envoy_builder
USER envoy_builder
WORKDIR /home/envoy_builder

# Start building Envoy
WORKDIR envoy
RUN git clone https://github.com/envoyproxy/envoy.git ./

RUN wget https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.1/clang+llvm-17.0.1-aarch64-linux-gnu.tar.xz \
    && tar -xvf clang+llvm-17.0.1-aarch64-linux-gnu.tar.xz \
    && rm clang+llvm-17.0.1-aarch64-linux-gnu.tar.xz
RUN bazel/setup_clang.sh ~/envoy/clang+llvm-17.0.1-aarch64-linux-gnu

RUN echo "build --config=clang --define tcmalloc=gperftools" >> user.bazelrc
RUN bazel build --define tcmalloc=gperftools -c opt envoy.stripped --jobs=$(nproc)

CMD ["/bin/bash"]