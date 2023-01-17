#!/bin/sh -x

set -eu

echo "Memory and swap:"
free
echo
swapon --show
echo
        
echo "Disk space report before modification"
df -h

echo "Listing 100 largest packages"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100


echo "remove 4GiB of images"
sudo systemd-run docker system prune --force --all --volumes
df -h

echo "Removing large packages"
sudo apt-get remove -y '^ghc-8.*'
sudo apt-get remove -y '^dotnet-.*'
sudo apt-get remove -y '^llvm-.*'
sudo apt-get remove -y 'php.*'
sudo apt-get remove -y azure-cli google-cloud-sdk hhvm google-chrome-stable firefox powershell mono-devel
sudo apt-get remove -y firefox
sudo apt-get autoremove -y
sudo apt-get clean
df -h

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
  
echo "Free space after reclaim"  
df -h
