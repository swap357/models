#!/bin/bash

for i in $(find . -name *requirements.txt) ; do stripped="${i:2:-17}" ; echo "${stripped}." ; trivy fs --format spdx-json --list-all-pkgs --scanners vuln -o "${stripped}/trivy-scan-spdx.json" "${stripped}" ; done
