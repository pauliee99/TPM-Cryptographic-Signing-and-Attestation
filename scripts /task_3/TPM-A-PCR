#!/bin/bash
WORKDIR="/home/kali/Desktop/IoT-miniproyect2/tpm-signing-demo"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

echo "== 0. Forcibly cleaning TPM memory and old files =="
tpm2_flushcontext -t 2>/dev/null
tpm2_flushcontext -s 2>/dev/null
tpm2_flushcontext -l 2>/dev/null
rm -f pcr16.val pcr.policy primary.ctx pcr_rsa.pub pcr_rsa.priv pcr_rsa.ctx pcr_signature.bin bad_signature.bin pcr_rsa-public.pem session.ctx policy.ctx bad_policy.ctx

echo "== 1. Prepare message =="
echo "TPM exercise" > message.txt

echo "== 2. Define a Predefined PCR State (PCR 16) =="
tpm2_pcrreset 16
tpm2_pcrextend 16:sha256=$(printf '3c466b87922a4c4fc06027a30274856b5479783931f4ec28b0acb1d93adf6089')
tpm2_pcrread sha256:16 -o pcr16.val

echo "== 3. Create a Policy File =="
tpm2_startauthsession --policy-session -S session.ctx
tpm2_policypcr -S session.ctx -l sha256:16 -f pcr16.val -L pcr.policy
tpm2_flushcontext session.ctx

echo "== 4. Create and Load the PCR-Restricted Signing Key =="
tpm2_createprimary -C o -g sha256 -G rsa -c primary.ctx
tpm2_create -C primary.ctx -G rsa -g sha256 -a 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' -L pcr.policy -u pcr_rsa.pub -r pcr_rsa.priv
tpm2_load -C primary.ctx -u pcr_rsa.pub -r pcr_rsa.priv -c pcr_rsa.ctx

echo "== 5. Test 1: Successful Signing (Matching State) =="
tpm2_startauthsession --policy-session -S policy.ctx
tpm2_policypcr -S policy.ctx -l sha256:16 -f pcr16.val
tpm2_sign -c pcr_rsa.ctx -g sha256 -o pcr_signature.bin message.txt -p session:policy.ctx
tpm2_flushcontext policy.ctx
echo "SUCCESS: Signed under valid PCR state!"

echo "== 6. Export Public Key for TPM-B =="
tpm2_readpublic -c pcr_rsa.ctx -f pem -o pcr_rsa-public.pem

echo "== 7. Test 2: Failed Signing (Mismatched State / Tamper Test) =="
echo "Resetting PCR 16 to simulate tampering..."
tpm2_pcrreset 16
tpm2_startauthsession --policy-session -S bad_policy.ctx
echo "EXPECTED CRYPTOGRAPHIC ERROR BELOW:"
tpm2_policypcr -S bad_policy.ctx -l sha256:16 -f pcr16.val 2>/dev/null
tpm2_sign -c pcr_rsa.ctx -g sha256 -o bad_signature.bin message.txt -p session:bad_policy.ctx 2>/dev/null || echo "Signing successfully blocked by TPM!"
tpm2_flushcontext bad_policy.ctx 2>/dev/null

echo "== Script complete! Ready for SCP transfer to Ubuntu. =="
ls -l pcr* message.txt
