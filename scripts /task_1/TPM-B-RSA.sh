#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

# TPM 2.0 RSA signature verification demonstration for Device B.
# Device B verifies a signature created by Device A.
# The original message, signature and public key must come from Device A.

WORKDIR="/home/kali/Desktop/IoT-miniproyect2/tpm-signing-demo-verification"

MESSAGE="${WORKDIR}/message.txt"
SIGNATURE="${WORKDIR}/signature.bin"
VERIFIED_PUBLIC="${WORKDIR}/rsa-public.pem"
VERIFIER="${WORKDIR}/verifier.ctx"

mkdir -p "$WORKDIR"
chmod 700 "$WORKDIR"

echo "== 1. Check TPM connectivity =="

if ! tpm2_getcap properties-fixed >/dev/null; then
    echo "ERROR: Cannot communicate with the TPM."
    exit 1
fi

echo "TPM is responding."

echo
echo "== 2. Check files received from Device A =="

for file in "$MESSAGE" "$SIGNATURE" "$VERIFIED_PUBLIC"; do
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Required file not found: $file"
        echo "Copy message.txt, signature.bin and rsa-public.pem from Device A."
        exit 1
    fi
done

echo "Message:"
cat "$MESSAGE"
echo

echo
echo "File sizes:"
stat -c '%n: %s bytes' "$MESSAGE" "$SIGNATURE" "$VERIFIED_PUBLIC"

echo
echo "== 3. Load Device A's public key into Device B's TPM =="

# This loads the public key for verification.
# It does not import Device A's private key.
tpm2_loadexternal \
    -C o \
    -G rsa \
    -u "$VERIFIED_PUBLIC" \
    -c "$VERIFIER"

echo "Public key loaded."

echo
echo "== 4. Verify Device A's signature =="

# The signature format must match the format produced by Device A.
# Use -f plain only if signature.bin contains the raw RSA signature.
if tpm2_verifysignature \
    -c "$VERIFIER" \
    -g sha256 \
    -m "$MESSAGE" \
    -s "$SIGNATURE"; then

    echo "SUCCESS: Device B verified Device A's signature."
else
    echo "ERROR: Signature verification failed."
    echo "Check that the message, signature and public key all came from Device A."
    echo "Also check the signature format produced by tpm2_sign."
    exit 1
fi

echo "== Complete =="
echo "Device B verified the signature using Device A's public key."
