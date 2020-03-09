#!/bin/bash

## Check if OpenSSL is installed
if ! type "openssl" > /dev/null; then
  echo "[FATAL] Please install OpenSSL prior to running this command!"
  exit 1;
fi

## Check if a path is provided
if [ -z "$1" ]; then
    echo "[FATAL] Please provide a path to the SSL files like this: ./ssl-helper.sh ./www.example.com"
    exit 2;
fi

FILE_LOCATION=$1
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
    KEY_CSR="OK"
else
    KEY_CSR="Mismatch"
fi

## Check if the certificate matches the certificate request
if [ "$CRT" = "$CSR" ]; then
    CRT_CSR="OK"
else
    CRT_CSR="Mismatch"
fi

## Check if the certificate matches the private key
if [ "$CRT" = "$KEY" ]; then
    CRT_KEY="OK"
else
    CRT_KEY="Mismatch"
fi

## Print results
echo ""
echo "-------------------------------------------------------------------------------"
echo "Result for ${FILE_NAME}"

echo ""
echo "Private Key v/s Certificate Request: ${KEY_CSR}"
echo "Certificate v/s Certificate Request: ${CRT_CSR}"
echo "Certificate v/s Private Key: ${CRT_KEY}"
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

    # Check if an email address is set
    if [ ${#CSR_INFO_CN} -ge 25 ]; then
        CSR_INFO_CN=$(echo ${CSR_INFO} | sed 's/^.*CN=\(.*\) Subject Public Key Info: .*$/\1/')
        CSR_INFO_E=""
    fi

    echo "-------------------------------------------------------------------------------"
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

    echo "-------------------------------------------------------------------------------"
    echo "Certificate Info:"
    echo ""

    echo "Not Valid Before: $CRT_INFO_BEFORE"
    echo "Not Valid After: $CRT_INFO_AFTER"
fi

echo "-------------------------------------------------------------------------------"
