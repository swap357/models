#!/bin/bash
# This script will generate a trivy scan for every requirements.txt file that it can find in the $REF_MODELS_ROOT

# Requirements:
# 1. docker must be installed
# 2. the script must be run as a user that can use docker
# 3. The script must be run as a user that can write files to the current directory

# Inputs:
# 1. The root of the AI Reference Models directory (Default: ../../../)
# 2. The Ref Models Version (Default: 'v3.0.0')
# 3. ./shared_vars.sh

# Outputs:
# 1. All requirements.txt files under $REF_MODELS_ROOT will be collated into a file called
#	requirements_collated.txt
# 2. All requirements will be frozen and written to a file in the current directory called
# 	requirements_collated.frozen.txt
# 3. All original requirements.txt files will be saved in their original locations as
# 	requirements.txt.orig
# 4. Each requirements.txt file will be replaced with a version that has all the requirements
#	locked to a version that is compatible with all of the other requirements in this
# 	version of the AI Reference Models. 
# 5. Trivy will scan each locked requirements.txt file and generate a file called 
#	<number>trivy-scan-spdx.json in the same directory as the requirements.txt file,
#	where <number> is a sequential identifier that prevents filename collisions when 
# 	uploading to https://goto.intel.com/scr-prod

source "./shared_vars.sh"
DEBUG=1
DO_TRIVY_SCAN=1
CREATE_CSV_FILE=0
LOCK_VERSIONS=1

function debug () {
  if [[ "${DEBUG}" == "1" ]]
  then
    echo $1
  fi
}

debug "HOST_PATH=${HOST_PATH}"

# Create CSV
CSV_FILENAME="this.csv"
RM_VERSION="${RM_VERSION:=v3.0.0}"
REF_MODELS_ROOT="${REF_MODELS_ROOT:=../../../}"
REF_MODELS_ROOT_STRLEN=9
ORIG_REQUIREMENTS_FILENAME="${REQUIREMENTS_FILENAME}.orig"

function create_files () {
  IFS=$'\n' declare -g REQUIREMENTS_TXT_FILES=($(find ${REF_MODELS_ROOT} -name "${REQUIREMENTS_FILENAME}"))
  debug "Number of requirements.txt files: ${#REQUIREMENTS_TXT_FILES[@]}"
  rm -rf ${COLLATED_REQUIREMENTS_FILENAME}
}

function collate_requirements () {
  debug "Number of requirements.txt files: ${#REQUIREMENTS_TXT_FILES[@]}"
  for file in ${REQUIREMENTS_TXT_FILES[*]}
  do 
    debug "file = ${file}"
    local stripped="${file::-REQUIREMENTS_STRLEN}" 
    debug "stripped = ${stripped}"
    # collate the requirements
    oIFS=$IFS
    IFS=$'\n'
    local original_requirements=($(<${file}))
    debug "Number of requirements in ${file}: ${#original_requirements[@]}"
    for requirement in ${original_requirements[*]}
    do
      local stripped_req=$(python3 split-multi-delim.py ${requirement})
      debug "requirement: ${requirement}; stripped_req = ${stripped_req}"
      echo ${stripped_req} >> ${COLLATED_REQUIREMENTS_FILENAME}
    done
#    generate_csv_line  ${stripped_filename} ${stripped} ${trivy_filename}
  done
}

function lock_versions () {
  if [[ "${LOCK_VERSIONS}" == "1" ]] 
  then
    # install all requirements in isolated environment
    docker run -ti --rm --disable-content-trust --name="ref-mod-reqs" -e https_proxy -e http_proxy -e HTTPS_PROXY -e HTTP_PROXY -e no_proxy -e NO_PROXY -v $(pwd):${HOST_PATH} -w ${HOST_PATH} ubuntu ${HOST_PATH}/install-reqs.sh
    local ret_val=$?
    if [[ "${ret_val}" != "0" ]]
    then
      echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&OOOOOOOOOOOOOOOOOOOOOOOOPPPPPPPPPPPPPPPSSSSSSSSSSSSSSSSSS"
      exit -1
    fi
  fi
}

function generate_new_requirements_files () {
  #replace all versions with the frozen/reconciled version
  IFS=$'\n' declare requirements_versions=($(<${FROZEN_COLLATED_REQUIREMENTS_FILENAME}))
  if [[ "${DEBUG}" == "1" ]]
  then
    cat ${requirements_versions}
  fi

  for file in ${REQUIREMENTS_TXT_FILES[*]}
  do
    local backup_file="${file}.orig"
    cp "$file" "${backup_file}"
    rm -f "${file}"
    oIFS=$IFS
    IFS=$'\n'
    local original_requirements=($(<${backup_file}))
    debug "Number of requirements in ${backup_file}: ${#original_requirements[@]}"
    for r in ${original_requirements[*]}
    do
      local stripped_req=$(python3 split-multi-delim.py ${r})
      if [[ "$stripped_req" != "" ]] 
      then
        for vr in ${requirements_versions[*]}
        do
          local requirement_base=$(echo ${vr} | cut -d '=' -f 1)
          debug "Original Requirement: ${r}; Original without version: ${stripped_req}"
          debug "Locked Requirement: ${vr}; Locked Requirement without version: ${requirement_base}"
          if [[ "${requirement_base,,}" = "${stripped_req,,}" ]]
          then
            debug "****match****"
            echo ${vr} >> ${file}
            break
          fi
        done
      else
        debug "python returned an error."
      fi
      stripped_req=""
    done
    original_requirements=()
    if [[ "${DEBUG}" == "1" ]] 
    then
      echo "!!!!!!!!!${backup_file}:"
      cat "${backup_file}"
    fi
  done
}

 # Append a counter to the end of the filename because the OneBoM SCR/Elements tool doesn't like it
# When we submit multiple trivy scans with the same filename.
function do_trivy_scan () {
  trivy fs --format spdx-json --list-all-pkgs --scanners vuln -o "${1}" "${2}"
}

function do_trivy_scans () {
  if [[ "${DO_TRIVY_SCAN}" == "1" ]]
  then
    local j=0
    for file in ${REQUIREMENTS_TXT_FILES[*]}
    do
      local stripped="${file::-REQUIREMENTS_STRLEN}"
      # do trivy scan
      local trivy_filename="${stripped}/${j}trivy-scan-spdx.json"
      do_trivy_scan "${trivy_filename}" "${file}"
      ((j++))
    done
  fi
}

function clean_up () {
  # Now that trivy scans are done, restore the original requirements.txt files
  for file in ${REQUIREMENTS_TXT_FILES[*]}
  do
    rm -f ${file}
    mv "${file}.orig" ${file}
  done
}

create_files
collate_requirements
if [[ "${DEBUG}" == "1" ]]
then 
  if [[ "${CREATE_CSV_FILE}" == "1" ]]
  then
    cat "${CSV_FILENAME}"
  fi
  cat ${COLLATED_REQUIREMENTS_FILENAME}
fi
lock_versions
generate_new_requirements_files
do_trivy_scans
#clean_up
echo "!!!!!! DONE !!!!!"
