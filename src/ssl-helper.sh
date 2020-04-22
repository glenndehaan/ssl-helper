#!/bin/bash

## Set command input
FILE_LOCATION=$1

## Cleanup Terminal
clear

## Terminal Colors
COLOR_RED="\033[91m"
COLOR_GREEN="\033[92m"
COLOR_YELLOW="\033[93m"
COLOR_PURPLE="\033[95m"
COLOR_RESET="\033[m"

## Output Branding
echo -e $COLOR_PURPLE
echo " ______     ______     __            __  __     ______     __         ______   ______     ______    ";
echo "/\  ___\   /\  ___\   /\ \          /\ \_\ \   /\  ___\   /\ \       /\  == \ /\  ___\   /\  == \   ";
echo "\ \___  \  \ \___  \  \ \ \____     \ \  __ \  \ \  __\   \ \ \____  \ \  _-/ \ \  __\   \ \  __<   ";
echo " \/\_____\  \/\_____\  \ \_____\     \ \_\ \_\  \ \_____\  \ \_____\  \ \_\    \ \_____\  \ \_\ \_\ ";
echo "  \/_____/   \/_____/   \/_____/      \/_/\/_/   \/_____/   \/_____/   \/_/     \/_____/   \/_/ /_/ ";
echo -e $COLOR_RESET

## Check if OpenSSL is installed
if ! type "openssl" > /dev/null; then
  echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} Please install OpenSSL prior to running this command!"
  exit 1;
fi

## Set script directory
SCRIPT_DIR="$(cd "$( dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

#
# Runs the SSL checks
#
check_ssl () {
    ## Check if a path is provided
    if [ -z "$FILE_LOCATION" ]; then
        echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} Please provide a path to the SSL files like this: ./ssl-helper.sh ./www.example.com"
        exit 2;
    fi

    REAL_FILE_LOCATION=$(realpath ${FILE_LOCATION})
    FILE_NAME=${REAL_FILE_LOCATION##*/}

    ## Check if all certificate files are in place and get file info if they are there
    if [ ! -f "${REAL_FILE_LOCATION}/${FILE_NAME}.key" ]; then
        echo "[WARNING] Missing Private Key file in: ${REAL_FILE_LOCATION}/${FILE_NAME}.key"
        KEY="0 <- File Missing..."
    else
        KEY=$(openssl rsa -noout -modulus -in ${REAL_FILE_LOCATION}/${FILE_NAME}.key | openssl md5)
    fi

    if [ ! -f "${REAL_FILE_LOCATION}/${FILE_NAME}.csr" ]; then
        echo "[WARNING] Missing Certificate Request file in: ${REAL_FILE_LOCATION}/${FILE_NAME}.csr"
        CSR="0 <- File Missing..."
        CSR_INFO=0
    else
        CSR=$(openssl req -noout -modulus -in ${REAL_FILE_LOCATION}/${FILE_NAME}.csr | openssl md5)
        CSR_INFO=$(openssl req -text -noout -in ${REAL_FILE_LOCATION}/${FILE_NAME}.csr)
    fi

    if [ ! -f "${REAL_FILE_LOCATION}/${FILE_NAME}.crt" ]; then
        echo "[WARNING] Missing Certificate file in: ${REAL_FILE_LOCATION}/${FILE_NAME}.crt"
        CRT="0 <- File Missing..."
        CRT_INFO=0
    else
        CRT=$(openssl x509 -noout -modulus -in ${REAL_FILE_LOCATION}/${FILE_NAME}.crt | openssl md5)
        CRT_INFO=$(openssl x509 -in ${REAL_FILE_LOCATION}/${FILE_NAME}.crt -text -noout | sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/ /g' | tr -s " ")
    fi

    ## Check if the private key matches the certificate request
    if [ "$KEY" = "$CSR" ]; then
        KEY_CSR="${COLOR_GREEN}OK${COLOR_RESET}"
    else
        KEY_CSR="${COLOR_RED}Mismatch${COLOR_RESET}"
    fi

    ## Check if the certificate matches the certificate request
    if [ "$CRT" = "$CSR" ]; then
        CRT_CSR="${COLOR_GREEN}OK${COLOR_RESET}"
    else
        CRT_CSR="${COLOR_RED}Mismatch${COLOR_RESET}"
    fi

    ## Check if the certificate matches the private key
    if [ "$CRT" = "$KEY" ]; then
        CRT_KEY="${COLOR_GREEN}OK${COLOR_RESET}"
    else
        CRT_KEY="${COLOR_RED}Mismatch${COLOR_RESET}"
    fi

    ## Print results
    echo ""
    echo -e $COLOR_YELLOW
    echo "-------------------------------------------------------------------------------"
    echo -e $COLOR_RESET
    echo -e "Result for ${COLOR_YELLOW}${FILE_NAME}${COLOR_RESET}"

    echo ""
    echo -e "Private Key v/s Certificate Request: ${KEY_CSR}"
    echo -e "Certificate v/s Certificate Request: ${CRT_CSR}"
    echo -e "Certificate v/s Private Key: ${CRT_KEY}"
    echo ""

    echo "Raw output (MD5):"
    echo "Private Key: ${KEY}"
    echo "Certificate Request: ${CSR}"
    echo "Certificate: ${CRT}"

    if [ "$CSR_INFO" != 0 ]; then
        CSR_INFO_C=$(echo ${CSR_INFO} | sed 's/^.*C=\(.*\), ST=.*$/\1/')
        CSR_INFO_ST=$(echo ${CSR_INFO} | sed 's/^.*ST=\(.*\), L=.*$/\1/')
        CSR_INFO_L=$(echo ${CSR_INFO} | sed 's/^.*L=\(.*\), O=.*$/\1/')
        CSR_INFO_O=$(echo ${CSR_INFO} | sed 's/^.*O=\(.*\), OU=.*$/\1/')
        CSR_INFO_OU=$(echo ${CSR_INFO} | sed 's/^.*OU=\(.*\), CN=.*$/\1/')
        CSR_INFO_CN=$(echo ${CSR_INFO} | sed 's/^.*CN=\(.*\)\/.*$/\1/')
        CSR_INFO_E=$(echo ${CSR_INFO} | sed 's/^.*emailAddress=\(.*\) Subject.*$/\1/')

        ## Check if an email address is set
        if [ ${#CSR_INFO_CN} -ge 25 ]; then
            CSR_INFO_CN=$(echo ${CSR_INFO} | sed 's/^.*CN=\(.*\) Subject Public Key Info: .*$/\1/')
            CSR_INFO_E=""
        fi

        echo -e $COLOR_YELLOW
        echo "-------------------------------------------------------------------------------"
        echo -e $COLOR_RESET
        echo "Certificate Request Info:"
        echo ""

        echo "Country Code: $CSR_INFO_C"
        echo "State or Province Name: $CSR_INFO_ST"
        echo "Locality Name: $CSR_INFO_L"
        echo "Organization Name: $CSR_INFO_O"
        echo "Organizational Unit Name: $CSR_INFO_OU"
        echo "Common Name: $CSR_INFO_CN"
        echo "Email address: $CSR_INFO_E"
    fi

    if [ "$CRT_INFO" != 0 ]; then
        CRT_INFO_BEFORE=$(echo ${CRT_INFO} | sed 's/^.*Before: \(.*\) Not.*$/\1/')
        CRT_INFO_AFTER=$(echo ${CRT_INFO} | sed 's/^.*After : \(.*\) Subject: .*$/\1/')

        echo -e $COLOR_YELLOW
        echo "-------------------------------------------------------------------------------"
        echo -e $COLOR_RESET
        echo "Certificate Info:"
        echo ""

        echo "Not Valid Before: $CRT_INFO_BEFORE"
        echo "Not Valid After: $CRT_INFO_AFTER"
    fi

    echo -e $COLOR_YELLOW
    echo "-------------------------------------------------------------------------------"
    echo -e $COLOR_RESET
}

#
# Create a new Private Key/CSR
#
create_ssl () {
    ## Check if a common name is provided
    if [ -z "$FILE_LOCATION" ]; then
        echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} Please provide a common name like this: ./ssl-helper.sh www.example.com"
        exit 2;
    fi

    CSR_C=""
    CSR_ST=""
    CSR_L=""
    CSR_O=""
    CSR_OU=""
    CSR_CN=$FILE_LOCATION
    CSR_E=""

    REAL_FILE_LOCATION="$(pwd)/${FILE_LOCATION}"

    ## Check if the private key already exists (Then don't override this)
    if [ -f "$REAL_FILE_LOCATION/$FILE_LOCATION.key" ]; then
        echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} The following file already exists: $REAL_FILE_LOCATION/$FILE_LOCATION.key"
        exit 3;
    fi

    ## Check if an ssl-helper.defaults.conf is in the directory
    if [ ! -f "$SCRIPT_DIR/ssl-helper.defaults.conf" ]; then
        echo -e "$COLOR_YELLOW[WARNING]$COLOR_RESET Missing defaults: $SCRIPT_DIR/ssl-helper.defaults.conf"
    else
        source "$SCRIPT_DIR/ssl-helper.defaults.conf"
    fi

    echo ""
    echo "Follow the instructions below:"
    echo ""

    mkdir -p $REAL_FILE_LOCATION
    if [ ! -f "$SCRIPT_DIR/ssl-helper.defaults.conf" ]; then
        openssl req -out $REAL_FILE_LOCATION/$FILE_LOCATION.csr -new -newkey rsa:2048 -nodes -keyout $REAL_FILE_LOCATION/$FILE_LOCATION.key
    else
        openssl req -out $REAL_FILE_LOCATION/$FILE_LOCATION.csr -new -newkey rsa:2048 -nodes -keyout $REAL_FILE_LOCATION/$FILE_LOCATION.key -subj "/C=${CSR_C}/ST=${CSR_ST}/L=${CSR_L}/O=${CSR_O}/OU=${CSR_OU}/CN=${CSR_CN}/emailAddress=${CSR_E}"
    fi
}

## Ask user what to run
echo "Select one of the options below:"
echo "1. Check an SSL certificate"
echo "2. Create a Private Key/Certificate Request pair"
echo ""
echo -n "Enter your selection and press [ENTER]: "
read user_selection

if [ "$user_selection" == 1 ]; then
    check_ssl
elif [ "$user_selection" == 2 ]; then
    create_ssl
else
    echo -e "${COLOR_RED}[FATAL]${COLOR_RESET} Incorrect option!"
fi
