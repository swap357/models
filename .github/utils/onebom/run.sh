#!/bin/bash

# This script outlines how to use the other scripts in this folder to generate AI Ref Model
# specific OneBoM files. It needs to be run on a host that has docker, and as a user 
# with permissions to use docker.

# The artifacts that are needed for the next step in the oneBoM process are:
# 1. The tarball of trivy scans
# 2. The tarball of updated requirements.txt files

# Step 1: Generate the Trivy Scans. 
./generate-trivy-scans.sh

# Step 2: Generate the Tarball of Trivy scans
./generate-tarball.sh

# Step 3: Generate the Tarball of updated requirements.txt files. 
TARBALL_FILENAME="pinned-requirements.tgz" FILELIST_TXT="pinned-reqs-file-list.txt" FILE_PATTERN="requirements.txt" ./generate-tarball.sh

