#!/usr/bin/env bash
read -sp "Password: " pass 
echo root:$pass | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
useradd -mG wheel -s /bin/bash jake
read -sp "Password: " usrpass
echo jake:$usrpass | chpasswd
echo "Run Arch.exe config --default-user jake in powershell"
