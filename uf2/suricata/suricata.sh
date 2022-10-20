#!/bin/bash

config=/etc/suricata/suricata.yaml

custom() {
    sudo rm /var/lib/suricata/rules/local.rules
    echo '
alert ssh any any -> any any (msg: "SSH connection found"; flow:to_server, not_established; sid:2000001; rev:1;)
alert icmp any any -> any any (msg: "ICMP Packet found"; sid:2000002; rev:1;)
' | sudo tee -a /var/lib/suricata/rules/local.rules > /dev/null
    sudo kill -usr2 $(pidof suricata)
    sudo suricata -T -c /etc/suricata/suricata.yaml -v
}

install() {

    command -v suricata >/dev/null 2>&1 || {
        sudo apt update
        sudo apt install -y software-properties-common
        sudo add-apt-repository ppa:oisf/suricata-stable -y
        sudo apt -y install suricata
    }

    ##### CONFIGURE

    sudo sed -i 's/community-id: false/community-id: true/g' $config

    command -v ip >/dev/null 2>&1 || sudo apt install -y iproute2 >/dev/null 2>&1
    command -v jp >/dev/null 2>&1 || sudo apt install -y jp
    echo "search for af-packet:"
    # TODO if eth0 all ok
    ip -p -j route show default | jp [].dev

    # Live Rule Reloading
    if grep -q "rule-reload" $config; then
        :
    else
        echo "
detect-engine:
  - rule-reload: true" | sudo tee -a $config >/dev/null
    fi

    ## TODO test file exists
    sudo suricata-update

    ## TODO
    # App-Layer protocol rdp enable status not set, so enabling by default. This behavior will change in Suricata 7, so please update your config. See ticket #4744 for more details.

}

log() {
    tail /var/log/suricata/fast.log
}


case $1 in
custom)
    custom
    ;;
install)
    install
    ;;
log)
    log
    ;;
*)
    echo "$0 install"
    ;;
esac
