# No auth
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_small.bin http://192.168.32.55:4002; done > results/noauth_small.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_medium.bin http://192.168.32.55:4002; done > results/noauth_medium.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_large.bin http://192.168.32.55:4002; done > results/noauth_large.log


# Do Envoy only
sleep 5
sudo systemctl start edge-device-envoy.service
sleep 5
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_small.bin http://127.0.0.1:4002; done > results/envoy_small.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_medium.bin http://127.0.0.1:4002; done > results/envoy_medium.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_large.bin http://127.0.0.1:4002; done > results/envoy_large.log

# Do full auth, requires a pause while human swaps around configs and whatnot
echo "Waiting for human intervention..."
for i in {1..10}; do read -r; done

for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_small.bin http://127.0.0.1:4002; done > results/full_small.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_medium.bin http://127.0.0.1:4002; done > results/full_medium.log
for i in {1..5}; do hey -z 10m -m POST -T "application/octet-stream" -D packets/packet_data_large.bin http://127.0.0.1:4002; done > results/full_large.log
