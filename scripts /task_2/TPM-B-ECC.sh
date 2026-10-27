#!/bin/bash
echo "== 1. Load ECC public key into TPM-B =="
tpm2_loadexternal -G ecc -C o -u ecc-public.pem -c ecc_verify.ctx

echo "== 2. Verify ECC Signature =="
tpm2_verifysignature -c ecc_verify.ctx -g sha256 -m message.txt -s ecc_signature.bin
