#!/usr/bin/env bash

ip link add name br0 type bridge
ip link set dev br0 up
ip address add 10.0.0.200/24 dev br0
ip route append default via 10.0.0.1 dev br0
ip link set enp7s0 master br0
ip address del 10.0.0.200/24 dev enp7s0
nmcli connection modify br0 ipv4.dns 10.0.0.3, 10.0.0.1
