$vm = Read-Host "Whats the name of the VM?"
Add-VMGPUPartitionAdapter -VMName $vm
Set-VMGPUPartitionAdapter -VMName $vm -MinPartitionVRAM 50000000 -MaxPartitionVRAM 500000000 -OptimalPartitionVRAM 500000000 -MinPartitionEncode 50000000 -MaxPartitionEncode 500000000 -OptimalPartitionEncode 500000000 -MinPartitionDecode 50000000 -MaxPartitionDecode 500000000 -OptimalPartitionDecode 500000000 -MinPartitionCompute 50000000 -MaxPartitionCompute 500000000 -OptimalPartitionCompute 500000000
Set-VM -GuestControlledCacheTypes $true -VMName $vm
Set-VM -LowMemoryMappedIoSpace 1Gb -VMName $vm
Set-VM -HighMemoryMappedIoSpace 32GB -VMName $vm


