#!/bin/bash

#set -xv

source "./shared_vars.sh"
CREATE_TARBALL=1

TARBALL_FILENAME="${TARBALL_FILENAME:=SCR-trivy-scans.tgz}"
FILE_LIST_TXT="${FILE_LIST_TXT:=trivy-file-list.txt}"
FILE_PATTERN="${FILE_PATTERN:=*spdx.json}"

function create_file_list () {
  IFS=$'\n' declare -g FOUND_FILES=($(find ${REF_MODELS_ROOT} -name "${FILE_PATTERN}"))
  debug "Number of files to include in tarball: ${#FOUND_FILES[@]}"
  rm -f "${FILE_LIST_TXT}"
  for file in "${FOUND_FILES[@]}"
  do
    echo "${file}" >> "${FILE_LIST_TXT}"
  done
  #header rows
}

function create_tarball () {
  tar -czvf "${TARBALL_FILENAME}" -T "${FILE_LIST_TXT}"
}


create_file_list
if [[ "${DEBUG}" == "1" ]]
then 
  cat "${FILE_LIST_TXT}"
fi
create_tarball
echo "!!!!!! DONE !!!!!"
