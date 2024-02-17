#!/bin/bash

imageURL=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
imageName="jammy-server-cloudimg-amd64.img"
volumeName="local-lvm"
virtualMachineId="9000"
templateName="jammy-tpl"
tmp_cores="2"
tmp_memory="2048"
rootPasswd="password"
cpuTypeRequired="host"
sshKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDM92Vb893P/I2bBiJeY0Q7kNjfizy4nVcj1lRS08VyVHpLCivBIZLFn0eKDss2LbSh0oXnrFug4Ez3vnRi63Sg1fPgUtPP0omwoQahlFTLmZ27mYeDkRxD3mCrjeFwajaqjwnhV3dvAe9+1D4Na9J0cq2RZphKzPLaNRM74qrHGb1RIsUqPFbWlDRKenOP2kvS/lEIVqKpnlFnqK3NPh4+27D0od5+doYx6Q9WFwPpVSNyZf9UXsknZhvuS6P2xVcfm2pTZBeAlhbHILdw/3HVs+koA8YmedH9bWy/ZEKl6gGkpErAm/lfEbkmj2H0ZmgkAJaIvODJskH5Fzal0HMp mishadronov"

apt update
apt install libguestfs-tools -y
rm *.img
wget -O $imageName $imageURL
qm destroy $virtualMachineId
virt-customize -a $imageName --install qemu-guest-agent
virt-customize -a $imageName --root-password password:$rootPasswd --ssh-inject root:file:/root/.ssh/authorized_keys
echo $sshKey > authorized_keys
virt-customize -a $imageName --upload authorized_keys:/root/.ssh/authorized_keys

qemu-img resize $imageName +50G
mv $imageName ${imageName/.img/-resized.img}

virt-resize --expand /dev/sda1 ${imageName/.img/-resized.img} $imageName

qm create $virtualMachineId --name $templateName --memory $tmp_memory --cores $tmp_cores --net0 virtio,bridge=vmbr0
qm importdisk $virtualMachineId ${imageName/.img/-resized.img} $volumeName
qm set $virtualMachineId --scsihw virtio-scsi-pci --scsi0 $volumeName:vm-$virtualMachineId-disk-0
qm set $virtualMachineId --boot c --bootdisk scsi0
qm set $virtualMachineId --ide2 $volumeName:cloudinit
qm set $virtualMachineId --serial0 socket --vga serial0
qm set $virtualMachineId --ipconfig0 ip=dhcp
qm set $virtualMachineId --cpu cputype=$cpuTypeRequired
qm template $virtualMachineId
