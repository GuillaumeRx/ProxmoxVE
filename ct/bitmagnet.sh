
#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2024 community-scripts ORG
# Author: guillaumerx
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://bitmagnet.io/

# App Default Values
APP="Bitmagnet"
var_tags="torrent"
var_cpu="1"
var_ram="1024"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /etc/bitmagnet ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP} LXC"
    systemctl stop bitmagnet
    go get -u github.com/bitmagnet-io/bitmagnet &>/dev/null
    systemctl start bitmagnet
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:3333${CL}"
