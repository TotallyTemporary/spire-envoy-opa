# https://gist.github.com/rafaelhdr/954f8bac6796a22b77f4ef699bb3c22e
set -euo pipefail

sudo apt update && sudo apt -y upgrade
sudo apt install -y wget build-essential
wget https://github.com/HewlettPackard/netperf/archive/netperf-2.7.0.tar.gz
tar -zxvf netperf-2.7.0.tar.gz
cd netperf-netperf-2.7.0/
git init
git apply ../netperf.diff # stolen from: https://github.com/cloud-bulldozer/k8s-netperf/blob/main/containers/netperf.diff
./configure && make && sudo make install