

#!/usr/bin/bash

COMBINED_CONFIG_FILE=combined-config-file.conf
FINAL_CONFIG_FILE=final-config-file.conf

_create_final_configuration_file() {
    # convert the list of files into an array
    local CONFIG_FILE_LIST=($(echo ${1} | tr ':' ' '))
    local WORKING_DIR=${2}

    # removes any trailing whitespace from each file, if any
    # this is absolutely required when importing into ConfigMaps 
    # put quotes around values if extra spaces are necessary
    sed -i -e 's/\s*$//' -e '/^$/d' -e '/^#.*$/d' ${CONFIG_FILE_LIST[@]}

    # iterates over each file and prints (default awk behavior)
    # each unique line; only takes first value and ignores duplicates
    awk -F= '!line[$1]++' ${CONFIG_FILE_LIST[@]} > ${COMBINED_CONFIG_FILE}

    # have to export everything, and source it twice:
    # 1) first source is to realize variables
    # 2) second time is to realize references
    set -o allexport
    source ${COMBINED_CONFIG_FILE}
    source ${COMBINED_CONFIG_FILE}
    set +o allexport

    # use envsubst to realize value references
    cat ${COMBINED_CONFIG_FILE} | envsubst > ${FINAL_CONFIG_FILE}
}

__print_work() {
    echo
    echo "================== COMBINED CONFIGS BEFORE ================="
    cat ${COMBINED_CONFIG_FILE}
    echo "================ COMBINED CONFIGS BEFORE END ==============="

    echo
    echo "================= PROOF OF SUBST IN MEMORY ================="
    echo "KEY_1: ${KEY_1}"
    echo "SHARED_KEY_2: ${SHARED_KEY_2}"
    echo "=============== PROOF OF SUBST IN MEMORY END ==============="

    echo
    echo "================== PROOF OF SUBST IN FILE =================="
    cat ${FINAL_CONFIG_FILE}
    echo "================ PROOF OF SUBST IN FILE END ================"
    echo
}

WORKING_DIR=$(pwd)

while [[ $# -gt 0 ]]
do
    KEY="$1"
    REALIZE_VALUES='false'

    case ${KEY} in
        -f|--files)
            CONFIG_FILE_LIST=${2}
            shift # past argument
            shift # past value
            ;;
        -d|--directory)
            WORKING_DIR=${2}
            shift # past argument
            shift # past value
            ;;
    esac
done

cd ${WORKING_DIR}

_create_final_configuration_file ${CONFIG_FILE_LIST} ${WORKING_DIR} ${REALIZE_VALUES}

__print_work


