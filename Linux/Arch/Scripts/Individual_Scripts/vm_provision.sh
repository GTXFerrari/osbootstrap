#!/usr/bin/env bash

os_choice=$(gum choose --header="OS Choice" "Linux" "Windows")
case "$os_choice" in
Linux)
  image_name=$(gum input --prompt="Image Name: ")
  image_size=$(gum input --prompt="Image Size: " --placeholder="ex:25G,50G,100G")
  # All images are thin provisioned by default
  # qcow2 (Qemu), vmdx (VMware), vhdx (Microsoft)
  image_type=$(gum choose --limit 1 --header="Image Format" "qcow2" "raw" "vmdk" "vhdx")
  case "$image_type" in
  qcow2)
    image_suffix=qcow2
    ;;
  raw)
    image_suffix=img
    ;;
  vmdk)
    image_suffix=vmdk
    ;;
  vhdx)
    image_suffix=vhdx
    ;;
  esac
  if [[ $image_type == "qcow2" ]]; then
    image_suffix=qcow2
  elif [[ $image_type == "raw" ]]; then
    image_suffix=img
  elif [[ $image_type == "vmdk" ]]; then
    image_suffix=vmdk
  elif [[ $image_type == "vhdx" ]]; then
    image_suffix=vhdx
  fi
  sudo qemu-img create -f "$image_type" /var/lib/libvirt/images/"$image_name"."$image_suffix" "$image_size"

  vm_name=$(gum input --placeholder="Choose your vm name:")
  ram_amount=$(gum input --placeholder="RAM amount:")
  virt-install \
    --name "$vm_name" \
    --ram "$ram_amount"

  ;;
Windows)
  image_name=$(gum input --placeholder="Choose you image name")
  image_size=$(gum input --placeholder="Choose you image size (Example:25G,50G,100G)")
  # All images are thin provisioned by default
  # qcow2 (Qemu), vmdx (VMware), vhdx (Microsoft)
  image_type=$(gum choose --limit 1 --header="Choose your image format" "qcow2" "raw" "vmdk" "vhdx")
  if [[ $image_type == "qcow2" ]]; then
    image_suffix=qcow2
  elif [[ $image_type == "raw" ]]; then
    image_suffix=img
  elif [[ $image_type == "vmdk" ]]; then
    image_suffix=vmdk
  elif [[ $image_type == "vhdx" ]]; then
    image_suffix=vhdx
  fi
  sudo qemu-img create -f "$image_type" /var/lib/libvirt/images/"$image_name"."$image_suffix" "$image_size"
  ;;
esac

#NOTE: This is a WIP script
