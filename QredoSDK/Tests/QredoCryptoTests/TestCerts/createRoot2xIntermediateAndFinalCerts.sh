#!/bin/sh
#set -x # Uncomment to output each line as it is run, useful for debugging script

SSLEAY_CONFIG="-config ./openssl.cnf"
BATCH_OPTION='-batch' # Comment out to prevent automatic signing of certificates
ROOTCA_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestRootCA/emailAddress=admin@qredo.com"
INTERCA1_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestIntermediateCA-1/emailAddress=admin@qredo.com"
INTERCA2_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestIntermediateCA-2/emailAddress=admin@qredo.com"
CERT1_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert1 using Intermediate CA 1/emailAddress=admin@qredo.com"
CERT2_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert2 using Intermediate CA 1/emailAddress=admin@qredo.com"
CERT3_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert3 using Intermediate CA 1/emailAddress=admin@qredo.com"
CERT4_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert4 using Intermediate CA 1/emailAddress=admin@qredo.com"
CERT5_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert5 using Intermediate CA 1/emailAddress=admin@qredo.com"
CERT6_SUBJ="/C=UK/ST=England/L=London/O=Qredo Ltd (Test)/OU=Dev Unit Test/CN=TestCert6 using Intermediate CA 2/emailAddress=admin@qredo.com"
CERT1_NAME="clientCert1.1024.IntCA1"
CERT2_NAME="clientCert2.2048.IntCA1"
CERT3_NAME="clientCert3.4096.IntCA1"
CERT4_NAME="clientCert4.8192.IntCA1"
CERT5_NAME="clientCert5.2048.Revoked.IntCA1"
CERT6_NAME="clientCert6.2048.IntCA2"
PASSWORD="pass:password" #Password is 'password'
DIR="qredoTestCA"
INTERCA1_NAME="interCA1"
INTERCA2_NAME="interCA2"

function createIntermediateCA
{
	INTERCA_NAME=${1}
	INTERCA_SUBJ=${2}
	mkdir ${INTERCA_NAME} ${INTERCA_NAME}/certs ${INTERCA_NAME}/crl ${INTERCA_NAME}/newcerts ${INTERCA_NAME}/private
	openssl req $SSLEAY_CONFIG -new -keyout ${INTERCA_NAME}/private/${INTERCA_NAME}key.pem -out ${INTERCA_NAME}/${INTERCA_NAME}req.pem -subj "$INTERCA_SUBJ" -passout "$PASSWORD"
    openssl ca $SSLEAY_CONFIG ${BATCH_OPTION} -cert rootCA/rootCAcert.pem -keyfile rootCA/private/rootCAkey.pem -passin "$PASSWORD" -policy policy_anything -out ${INTERCA_NAME}/${INTERCA_NAME}cert.pem -days 1095 -extensions v3_ca -infiles ${INTERCA_NAME}/${INTERCA_NAME}req.pem
	openssl ca $SSLEAY_CONFIG -gencrl -keyfile ${INTERCA_NAME}/private/${INTERCA_NAME}key.pem -cert ${INTERCA_NAME}/${INTERCA_NAME}cert.pem -passin "$PASSWORD" -out ${INTERCA_NAME}/crl/${INTERCA_NAME}crl.pem
}

function createClientCert
{
	CERT_NAME=${1}
	CERT_KEY_TYPESIZE=${2}
	CERT_SUBJ=${3}
	INTERCA_NAME=${4}
	openssl req $SSLEAY_CONFIG -newkey $CERT_KEY_TYPESIZE -keyout clientCerts/${CERT_NAME}key.pem -out clientCerts/${CERT_NAME}req.pem -subj "$CERT_SUBJ" -passout "$PASSWORD"
	openssl ca $SSLEAY_CONFIG ${BATCH_OPTION} -cert ${INTERCA_NAME}/${INTERCA_NAME}cert.pem -keyfile ${INTERCA_NAME}/private/${INTERCA_NAME}key.pem -passin "$PASSWORD" -policy policy_anything -out clientCerts/${CERT_NAME}cert.pem -days 1095 -infiles clientCerts/${CERT_NAME}req.pem
    openssl pkcs12 -export -out clientCerts/${CERT_NAME}.pfx -inkey clientCerts/${CERT_NAME}key.pem -in clientCerts/${CERT_NAME}cert.pem -certfile ${INTERCA_NAME}/${INTERCA_NAME}cert.pem -passin "$PASSWORD" -passout "$PASSWORD"
}

# Be vary careful about using variables in rm commands, if variable is empty 'rm -rf ${DIR}/' equates to 'rm -rf /'!
echo "\n\nRemoving previous CA/certs"
rm -rf ./clientCerts/
rm -rf ./interCA?
rm -rf ./rootCA/
rm -rf ./qredoTestCA/
rm *.pem; 

echo "\n\nGenerating new CA/certs"

# Note: need to ensure the config file directories match the directories used in the script
mkdir "$DIR" "$DIR"/certs "$DIR"/crl "$DIR"/newcerts "$DIR"/private
touch "$DIR"/index.txt
echo 01 > "$DIR"/crlnumber

# create Root CA (4096 bit)
mkdir rootCA rootCA/certs rootCA/crl rootCA/newcerts rootCA/private
openssl req $SSLEAY_CONFIG -new -keyout rootCA/private/rootCAkey.pem -out rootCA/rootCAreq.pem -subj "$ROOTCA_SUBJ" -passout "$PASSWORD"
openssl ca $SSLEAY_CONFIG ${BATCH_OPTION} -create_serial -out rootCA/rootCAcert.pem -days 3650 -keyfile rootCA/private/rootCAkey.pem -passin "$PASSWORD" -selfsign -extensions v3_ca -infiles rootCA/rootCAreq.pem
openssl ca $SSLEAY_CONFIG -gencrl -keyfile rootCA/private/rootCAkey.pem -cert rootCA/rootCAcert.pem -passin "$PASSWORD" -out rootCA/crl/rootCAcrl.pem
           
# create Intermediate CA 1 (2048 bit)
createIntermediateCA "$INTERCA1_NAME" "$INTERCA1_SUBJ"
# create Intermediate CA 2 (2048 bit) - This will eventually be revoked
createIntermediateCA "$INTERCA2_NAME" "$INTERCA2_SUBJ"

# Create the chain files from root and intermediate CAs
cat rootCA/rootCAcert.pem "$INTERCA1_NAME"/"$INTERCA1_NAME"cert.pem rootCA/crl/rootCAcrl.pem "$INTERCA1_NAME"/crl/"$INTERCA1_NAME"crl.pem > "$INTERCA1_NAME"chainWithEmptyCrl.pem
cat rootCA/rootCAcert.pem "$INTERCA2_NAME"/"$INTERCA2_NAME"cert.pem rootCA/crl/rootCAcrl.pem "$INTERCA2_NAME"/crl/"$INTERCA2_NAME"crl.pem > "$INTERCA2_NAME"chainWithEmptyCrl.pem

mkdir clientCerts
# Create Client certificate 1024 bit (Intermediate 1)
createClientCert ${CERT1_NAME} "rsa:1024" "$CERT1_SUBJ" "$INTERCA1_NAME"
# Create Client certificate 2048 bit (Intermediate 1)
createClientCert ${CERT2_NAME} "rsa:2048" "$CERT2_SUBJ" "$INTERCA1_NAME"
# Create Client certificate 4096 bit (Intermediate 1)
createClientCert ${CERT3_NAME} "rsa:4096" "$CERT3_SUBJ" "$INTERCA1_NAME"
# Create Client certificate 8192 bit (Intermediate 1)
createClientCert ${CERT4_NAME} "rsa:8192" "$CERT4_SUBJ" "$INTERCA1_NAME"
# Create Client certificate 2048 bit (Intermediate 1) - This will eventually be revoked
createClientCert ${CERT5_NAME} "rsa:2048" "$CERT5_SUBJ" "$INTERCA1_NAME"
# Create Client certificate 2048 bit (Intermediate 2) - This won't be revoked, but the intermediate CA 2 will be revoked
createClientCert ${CERT6_NAME} "rsa:2048" "$CERT6_SUBJ" "$INTERCA2_NAME"

#TODO: DH - How to create an expired certificate as well? Valid for just 1 day? Issue is, can't use it immediately.

# Verify client certs using intermediate/root chains
echo "\n\nVerifying certs (before any are revoked)"
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithEmptyCrl.pem clientCerts/${CERT1_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithEmptyCrl.pem clientCerts/${CERT2_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithEmptyCrl.pem clientCerts/${CERT3_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithEmptyCrl.pem clientCerts/${CERT4_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithEmptyCrl.pem clientCerts/${CERT5_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA2_NAME"chainWithEmptyCrl.pem clientCerts/${CERT6_NAME}cert.pem

echo "\n\nRevoking client cert 5, and Intermediate CA 2"
# Revoke client cert 5 (Intermediate CA 1)
openssl ca $SSLEAY_CONFIG -keyfile rootCA/private/rootCAkey.pem -cert rootCA/rootCAcert.pem -revoke clientCerts/${CERT5_NAME}cert.pem -passin "$PASSWORD"
# Revoke Intermediate CA 2
openssl ca $SSLEAY_CONFIG -keyfile rootCA/private/rootCAkey.pem -cert rootCA/rootCAcert.pem -revoke "$INTERCA2_NAME"/"$INTERCA2_NAME"cert.pem -passin "$PASSWORD"

echo "\n\nUpdating CRLs"
# Update CRLs (Root and Intermediate 1 CA)
openssl ca $SSLEAY_CONFIG -gencrl -keyfile rootCA/private/rootCAkey.pem -cert rootCA/rootCAcert.pem -passin "$PASSWORD" -out rootCA/crl/rootCAcrlAfterRevoke.pem
openssl ca $SSLEAY_CONFIG -gencrl -keyfile "$INTERCA1_NAME"/private/"$INTERCA1_NAME"key.pem -cert "$INTERCA1_NAME"/"$INTERCA1_NAME"cert.pem -passin "$PASSWORD" -out "$INTERCA1_NAME"/crl/"$INTERCA1_NAME"crlAfterRevoke.pem
openssl ca $SSLEAY_CONFIG -gencrl -keyfile "$INTERCA2_NAME"/private/"$INTERCA2_NAME"key.pem -cert "$INTERCA2_NAME"/"$INTERCA2_NAME"cert.pem -passin "$PASSWORD" -out "$INTERCA2_NAME"/crl/"$INTERCA2_NAME"crlAfterRevoke.pem

# Add CRLs to the chains to allow CRL verification (must have CRLs signed by every CA chain - i.e. root and inter1/inter2)
cat rootCA/rootCAcert.pem "$INTERCA1_NAME"/"$INTERCA1_NAME"cert.pem rootCA/crl/rootCAcrlAfterRevoke.pem "$INTERCA1_NAME"/crl/"$INTERCA1_NAME"crlAfterRevoke.pem > "$INTERCA1_NAME"chainWithRevokedCrl.pem
cat rootCA/rootCAcert.pem "$INTERCA2_NAME"/"$INTERCA2_NAME"cert.pem rootCA/crl/rootCAcrlAfterRevoke.pem "$INTERCA2_NAME"/crl/"$INTERCA2_NAME"crlAfterRevoke.pem > "$INTERCA2_NAME"chainWithRevokedCrl.pem


echo "\n\nVerifying certs after revocation - client 5 and 6 should not verify. client 5 is rekoved, and client 6 has Intermediate CA2 revoked"
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithRevokedCrl.pem clientCerts/${CERT1_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithRevokedCrl.pem clientCerts/${CERT2_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithRevokedCrl.pem clientCerts/${CERT3_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithRevokedCrl.pem clientCerts/${CERT4_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA1_NAME"chainWithRevokedCrl.pem clientCerts/${CERT5_NAME}cert.pem
openssl verify -crl_check_all -CAfile "$INTERCA2_NAME"chainWithRevokedCrl.pem clientCerts/${CERT6_NAME}cert.pem
