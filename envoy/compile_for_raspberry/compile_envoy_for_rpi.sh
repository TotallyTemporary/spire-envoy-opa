# https://github.com/envoyproxy/envoy/issues/23339
# https://learn.arm.com/learning-paths/servers-and-cloud-computing/envoy/build_install_envoy/
# Raspberry Pi OS requires a compiler flag to be set
# --define tcmalloc=gperftools
# Note that this compilation took approximately 6 hours.

sudo nerdctl build -t custom-envoy:latest -f Dockerfile .
sudo nerdctl create --name temp custom-envoy:latest
sudo nerdctl cp custom-envoy:/home/envoy_builder/envoy/bazel-bin/source/exe/envoy-static ./
sudo nerdctl cp custom-envoy:/home/envoy_builder/envoy/bazel-bin/source/exe/envoy-static.stripped ./