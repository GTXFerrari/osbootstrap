# **Windows 11 Installation Guide**

**Windows 11 requires a TPM and secure boot enabled**[^1]

<img src="https://i.pcmag.com/imagery/reviews/00xBy0JjVybodfIwWxeGCkZ-1.fit_scale.size_760x427.v1628697239.png" width="500" height="300">


&nbsp;

## **ISO Creation**

* Download the ISO from https://www.microsoft.com/software-download/windows11
* Create a bootable USB using 
  * **Rufus** https://rufus.ie/en/ (*Windows Only*)
  * **WoeUSB** https://github.com/WoeUSB/WoeUSB (*Linux*)
  * **CLI** https://www.sysgeeker.com/how-to-create-windows-11-bootable-usb-on-mac.html (*macOS*)

&nbsp;

## **Installation**
* On the initial screen press **Shift+F10** to enter a cmd prompt
```ps1
# Run diskpart
diskpart

# Show attached disks
list disk

# Select disk (make sure not to select your USB drive or any disks you are using for other data)
select disk n   # Disk "n" can range from 0-10

# Once selected clean the disk and convert to GPT
clean
convert gpt
```

* Choose **Install now**
* Enter product key or choose **I don't have a product key**
* Choose Version **Pro**
* Accept EULA
* Choose **Custom: Install Windows only (advanced)**
  * Choose **Drive 0 Unallocated Space** & choose **New**
  * Enter **205824**[^2] for a 200GB C: Drive
  * Click **Apply** & **OK**
  * Choose **Next**
* Choose **Sign-in options**
  * Choose **Offline account**
  * Choose **Skip for now**
  * Enter Credentials
  * Turn off all telemetry

### Security Settings
  - [x] Enable Bitlocker
  - [x] Enable VBS (Virtualization-based Security)

&nbsp;

## Environment Setup

- [x] Install motherboard drivers + GPU drivers
- [x] Turn off "Pointer Precision" in windows mouse settings
- [x] Set power plan to high performance
- [x] Create D: 
- [x] Plug in ETH & run windows updates
- [x] Update windows store applications
- [x] Reboot

### WSL 2
```ps1
# Install wsl2  powershell admin prompt
wsl --install
```

### Applications (Non-winget)
1. **Veeam Agent for Microsoft Windows Free** https://www.veeam.com/downloads.html?ad=top-sub-menu
1. **Xbox Accessories**


### Application Skins/Mods
1. **Steam Metro & Unofficial Patch** https://metroforsteam.com/ ------ https://github.com/redsigma/UPMetroSkin 
1. **Better Discord** https://betterdiscord.app/


[^1]: This can be bypassed through tools like Rufus or through registry edits during install
[^2]: The formula to determine the size is *TB in MB x 1.048576 + 4096*  **OR** *GB in MB x 1.024 + 1024*
[^3]: GPU Overclock (1080ti) **Core +125 | Mem +500**
