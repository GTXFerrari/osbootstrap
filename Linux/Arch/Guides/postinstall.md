# **Post Install**

### **Config files**
```bash
# pacman.conf
Uncomment Color (line 33)
Add ILoveCandy to any open line

# makepkg.conf (C & C++ Flags)
CFLAGS="-march=native -O2 -pipe -fno-plt"
CXXFLAGS="${CFLAGS}"

# Rust Flags
RUSTFLAGS="-C opt-level=2 -C target-cpu=native"

# Make Flags
MAKEFLAGS="-j$(nproc)"
```
