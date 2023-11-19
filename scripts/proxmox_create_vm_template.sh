#!/bin/bash

[ $# -ne 2 ] && echo "ERROR:  Missing arguments!" && \
    echo "usage:  $0 <STORAGE_VOLUME> <MACHID>" && \
    exit 1

STORAGE_VOL=local-zfs
IMG_VER=v1.5.5
STORAGE_VOL=$1
MACHID=$2

IMG_ARCH=amd64
IMG_FILENAME=metal-${IMG_ARCH}.raw
IMG_FILENAME_XZ=${IMG_FILENAME}.xz
IMG_URL=https://github.com/siderolabs/talos/releases/download/${IMG_VER}/${IMG_FILENAME_XZ}
IMG_LOCAL_XZ=/tmp/$IMG_FILENAME_XZ
IMG_LOCAL=/tmp/$IMG_FILENAME

clear

list_versions() {
    repository="siderolabs/imager"
    token=$(curl -s "https://ghcr.io/token?scope=repository:$repository:pull" | jq -r '.token')
    last_version=""
    all_versions=()
    while true; do
        response=$(curl -s -H "Authorization: Bearer $token" "https://ghcr.io/v2/$repository/tags/list?n=1000&last=$last_version")
        tags=$(echo "$response" | jq -r '.tags')
        if [ "$tags" == "null" ]; then
            break
        fi
        readarray -t versions < <(echo "$response" | jq -c '.tags[]' | sed 's/"//g')
        for version in "${versions[@]}"; do
            all_versions+=("$version")
            last_version="$version"
            if [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                IMG_VER="$version"
            fi
        done
    done
}

check_storage_volume_exists() {
    # Let's confirm the storage id exists
    pvesm status | tail -n +2 | awk '{print $1}' | fgrep -q $STORAGE_VOL
    [ $? -ne 0 ] && \
        echo "ERROR:  Unable to find storage volume: $STORAGE_VOL" && \
        echo "        Found only these storage volumes: " && \
        pvesm status | tail -n +2 | awk '{print $1}' && \
        exit 1
}

download_talos_vm_image() {
    rm -f ${IMG_LOCAL}*
    wget -qO ${IMG_LOCAL_XZ} $IMG_URL
    xz -v -d ${IMG_LOCAL_XZ}
    ls -laF ${IMG_LOCAL}
}

create_vm_template() {
    # Create proxmox vm template
    qm destroy ${MACHID} || true
    # NOTE:  Need to create with bios ovmf and machine=q35 for UEIF bios
    # NOTE:  Talos REQUIRES bios.  It won't work with EUFI
    # NOTE: EUFI: bios:ovmf, machine=q35, efidisk0: ${STORAGE_VOL}:1,efitype=4m,pre-enrolled-keys=1,size=1M
    # NOTE: BOIS: bios: i440fx, machine=SeaBIOS
    qm create ${MACHID} \
        --bios seabios \
        --boot order=scsi0 \
        --cores 4 \
        --cpu cputype=x86-64-v2 \
        --machine pc \
        --memory 4096 \
        --name talos-template \
        --net0 virtio,bridge=vmbr0 \
        --ostype l26 \
        --scsi0 ${STORAGE_VOL}:0,import-from=${IMG_LOCAL},cache=writeback,discard=on \
        --scsihw virtio-scsi-pci \
        --sockets 1 \
        --template 1
    # For some unknown reason, specifying the SIZE in qm create --scsi0 is ignored
    qm resize 8000 scsi0 +100G
    rm -f ${IMG_LOCAL}

    sleep 5
}

list_versions
check_storage_volume_exists
download_talos_vm_image
create_vm_template
