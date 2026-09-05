#!/usr/bin/env bash
set -e

NODES=(
  "10.3.232.20"
  "10.3.232.21"
  "10.3.232.22"
  "10.3.232.30"
  "10.3.232.31"
  "10.3.232.33"
  "10.3.232.34"
  "10.3.232.35"
  "10.3.232.36"
  "10.3.232.37"
)

# Start tunnels
for ip in "${NODES[@]}"; do
  echo "Setting up reverse proxy tunnel to $ip..."
  ssh -N -f -R 8888:localhost:8888 -o StrictHostKeyChecking=no -o ServerAliveInterval=15 -o ServerAliveCountMax=3 "cpdt@$ip" || true
done

echo "Tunnels initialized."
