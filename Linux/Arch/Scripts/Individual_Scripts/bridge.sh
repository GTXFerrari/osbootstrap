#!/usr/bin/env bash

nmcli connection add type bridge ifname br0 stp no
nmcli connection add type bridge-slave ifname enp6s0 master br0
nmcli connection down 'Wired connection 2'
nmcli connection up bridge-br0
nmcli connection up bridge-slave-enps60
nmcli connection modify 'Wired connection 2' connection.autoconnect no
nmcli connection modify bridge-br0 ipv4.addresses "10.0.0.200/24"
nmcli connection modify bridge-br0 ipv4.dns "10.0.0.3 10.0.0.1"
nmcli conection modify bridge-br0 ipv4.method manual
nmcli connection up bridge-br0
nmcli connection modify bridge-br0 +ipv4.routes "0.0.0.0/0 10.0.0.1"
