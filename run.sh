git clone https://github.com/radicle-dev/radicle-bins.git
cd radicle-bins

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
apt install nodejs -y
npm install -g yarn
yarn set version latest

git clone https://github.com/radicle-dev/radicle-bins.git
apt install build-essential -y
cd radicle-bins/seed/ui && yarn && yarn build

cd ~/radicle-bins
mkdir -p ~/.radicle-seed
cargo run -p radicle-keyutil -- --filename ~/.radicle-seed/secret.key
echo "enter IP"
read ip
echo "enter Login"
read login

cat <<EOF > /root/radicle-bins/run.sh
#!/bin/bash
/root/radicle-bins/target/release/radicle-seed-node \
  --root /root/.radicle-seed \
  --peer-listen 0.0.0.0:12345 \
  --http-listen 0.0.0.0:81 \
  --name "$login" \
  --public-addr "$ip" \
  --assets-path /root/radicle-bins/seed/ui/public \
< /root/.radicle-seed/secret.key \

EOF

chmod +x /root/radicle-bins/run.sh


cat <<EOF > /etc/systemd/system/rad.service
[Unit]
Description=Radicle Daemon
After=network-online.target

[Service]
User=root
TimeoutStartSec=0
CPUWeight=90
IOWeight=90
ExecStart=/root/radicle-bins/run.sh

Restart=always
RestartSec=3
LimitNOFILE=65535
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

systemctl enable rad
systemctl start rad
cd
cd radicle-bins
cargo run -p radicle-seed-node --release
