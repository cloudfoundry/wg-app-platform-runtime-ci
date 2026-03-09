#!/bin/bash

# We need to reference the pcap header files when running `go vet` now that pcap support was added to diego.
# This isn't really related to checking out submodules, but it is a repo-specific hook that we already call in
# the shared task, so we can unpack the pcap blob here.

bosh sync-blobs

mkdir -p /tmp/libpcap
pcap_tgz=$(ls -1 blobs/libpcap/*.xz | head -1)
tar -xf blobs/ -C /tmp/libpcap
