#!/usr/bin/env bash

# Copyright (c) 2021-2024 community-scripts ORG
# Author: guillaumerx
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Golang"
cd /tmp
set +o pipefail
GO_RELEASE=$(curl -s https://go.dev/dl/ | grep -o -m 1 "go.*\linux-amd64.tar.gz")
wget -q https://golang.org/dl/${GO_RELEASE}
tar -xzf ${GO_RELEASE} -C /usr/local
ln -s /usr/local/go/bin/go /usr/bin/go
set -o pipefail
msg_ok "Installed Golang"

msg_info "Installing PostgreSQL"
$STD apt-get install -y postgresql postgresql-contrib
DB_NAME="bitmagnet"
DB_USER="bitmagnet"
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" 
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
msg_ok "Installed PostgreSQL"

msg_info "Installing bitmagnet"
$STD go install github.com/bitmagnet-io/bitmagnet
mkdir /etc/bitmagnet
cd ~
msg_ok "Installed bitmagnet"

msg_info "Creating bitmagnet configuration"
cat <<EOF >/etc/bitmagnet/config.yml
postgres:
  host: localhost
  name: $DB_NAME
  user: $DB_USER
  password: $DB_PASSWORD
EOF
msg_ok "Created bitmagnet configuration"

msg_info "Creating Services"
cat <<EOF >/etc/systemd/system/bitmagnet.service
[Unit]
Description=Bitmagnet is a self-hosted BitTorrent indexer, DHT crawler, content classifier and torrent search engine with web UI, GraphQL API and Servarr stack integration.

[Service]
WorkingDirectory=/etc/bitmagnet
ExecStart=/root/go/bin/bitmagnet worker run --keys=http_server --keys=queue_server --keys=dht_crawler
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now bitmagnet
sleep 2
systemctl enable -q --now bitmagnet
msg_ok "Created Services"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf go/
rm -rf /tmp/${GO_RELEASE}
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
