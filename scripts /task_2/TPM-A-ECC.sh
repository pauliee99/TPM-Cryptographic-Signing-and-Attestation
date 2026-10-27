#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

WORKDIR="/home/kali/Desktop/IoT-miniproyect2/tpm-signing-demo"
MESSAGE="${WORKDIR}/message.txt"
PRIMARY_CTX="${WORKDIR}/primary.ctx"
PUBLIC_KEY="${WORKDIR}/ecc.pub"
PRIVATE_KEY="${WORKDIR}/ecc.priv"
SIGNING_CTX="${WORKDIR}/ecc.ctx"
SIGNATURE="${WORKDIR}/ecc_signature.bin"
VERIFIED_PUBLIC="${WORKDIR}/ecc-public.pem"

mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"

echo "== 1. Check TPM connectivity =="

if ! tpm2_getcap properties-fixed >/dev/null; then
    echo "Cannot communicate with the TPM. Check /dev/tpm0, /dev/tpmrm0, and TPM permissions."
    exit 1
fi

echo "TPM is responding."

echo
echo "== 2. Prepare message =="

if [[ ! -f "$MESSAGE" ]]; then
    echo "Message file not found: $MESSAGE"
    exit 1
fi

cat "$MESSAGE"
echo

echo
echo "== 3. Create a primary key in the TPM =="

tpm2_createprimary \
    -C o \
    -G ecc \
    -g sha256 \
    -c "$PRIMARY_CTX"

echo
echo "== 4. Create an ECC signing key =="

tpm2_create \
    -C "$PRIMARY_CTX" \
    -G ecc \
    -g sha256 \
    -a 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' \
    -u "$PUBLIC_KEY" \
    -r "$PRIVATE_KEY"

echo
echo "== 5. Load ECC signing key into the TPM =="

tpm2_load \
    -C "$PRIMARY_CTX" \
    -u "$PUBLIC_KEY" \
    -r "$PRIVATE_KEY" \
    -c "$SIGNING_CTX"

echo
echo "== 6. Sign message with ECC/SHA-256 =="

tpm2_sign \
    -c "$SIGNING_CTX" \
    -g sha256 \
    -o "$SIGNATURE" \
    "$MESSAGE"

echo "Signature saved to: $SIGNATURE"
echo "Signature size: $(wc -c < "$SIGNATURE") bytes"

echo
echo "== 7. Verify signature using TPM key context =="

tpm2_verifysignature \
    -c "$SIGNING_CTX" \
    -g sha256 \
    -s "$SIGNATURE" \
    -m "$MESSAGE"

echo "TPM ECC signature verification succeeded."

echo
echo "== 8. Export ECC public key =="

tpm2_readpublic \
    -c "$SIGNING_CTX" \
    -f pem \
    -o "$VERIFIED_PUBLIC"

echo
echo "== Complete =="
echo "Working directory: $WORKDIR"
echo "Original message:  $MESSAGE"
echo "Signature:         $SIGNATURE"
echo "Public key:        $VERIFIED_PUBLIC"
echo
echo "Keep ecc.priv and the context files private."
echo "The .priv file is a TPM-protected key blob, not a plaintext ECC private key."
echo "The primary and signing keys are not persistent TPM objects."
