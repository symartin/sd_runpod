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
echo "Listing 100 largest packages"
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n | tail -n 100

echo "---"
echo "remove 4GiB of images"
sudo systemd-run docker system prune --force --all --volumes
df -h

echo "---"
echo "Removing large packages"
sudo apt-get remove -y '^dotnet.*' --fix-missing
sudo apt-get remove -y '^mysql.*' --fix-missing
sudo apt-get remove -y '^linux-azure-headers.*' --fix-missing
sudo apt-get remove -y azure-cli google-cloud-sdk hhvm google-chrome-stable firefox powershell microsoft-edge-stable  --fix-missing
sudo apt-get remove -y firefox aspnetcore-runtime-6.0 humanity-icon-theme --fix-missing
sudo apt-get autoremove -y
sudo apt-get clean
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
