#!/bin/sh -x

set -eu

echo "Memory and swap:"
free
echo "---"
swapon --show

echo "---"  
echo "Disk space report before modification"
df -h

echo "---"
echo "Listing 200 largest packages"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 200

echo "---"
echo "remove 4GiB of images"
sudo systemd-run docker system prune --force --all --volumes
df -h

echo "---"
echo "Removing large packages"
sudo apt-get remove -y '^mysql.*' 
sudo apt-get remove -y '^temurin.*' 
sudo apt-get remove -y '^llvm.*' 

sudo apt-get remove -y azure-cli google-cloud-sdk google-chrome-stable firefox powershell microsoft-edge-stable  
sudo apt-get remove -y firefox humanity-icon-theme mono-utils monodoc-manual --fix-missing
sudo apt-get remove -y firefox libllvm14 --fix-missing

sudo apt-get autoremove -y >/dev/null 2>&1
sudo apt-get clean
sudo apt-get autoremove -y >/dev/null 2>&1
sudo apt-get autoclean -y >/dev/null 2>&1
df -h

echo "---"
echo "remove large folder"
sudo systemd-run rm -rf \
  "$AGENT_TOOLSDIRECTORY" \
  /usr/share/dotnet/* \
  /opt/* \
  /usr/local/* \
  /usr/share/az* \
  /usr/share/gradle* \
  /usr/share/miniconda \
  /usr/share/swift \
  /usr/local/lib/android \
  /usr/local/share/boost

echo "---"
echo "Free space after reclaim"  
df -h
