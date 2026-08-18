#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/generate-example-certs.sh <domain> [output-dir]

Example:
  scripts/generate-example-certs.sh ejempo.com generated-ejempo-certs

Generates:
  ca.key
  ca.crt
  ca.srl
  tls.key
  tls.csr
  tls.ext
  tls.crt
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

domain="${1:-}"
if [[ -z "${domain}" ]]; then
  usage >&2
  exit 1
fi

output_dir="${2:-generated-${domain}-certs}"
org="${CERT_ORG:-Example}"
ca_days="${CA_DAYS:-3650}"
tls_days="${TLS_DAYS:-365}"
ca_bits="${CA_BITS:-4096}"
tls_bits="${TLS_BITS:-2048}"

mkdir -p "${output_dir}"

cat > "${output_dir}/tls.ext" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:*.${domain},DNS:*.admin.${domain}
EOF

openssl genrsa -out "${output_dir}/ca.key" "${ca_bits}"
openssl req -x509 -new -nodes \
  -key "${output_dir}/ca.key" \
  -sha256 \
  -days "${ca_days}" \
  -out "${output_dir}/ca.crt" \
  -subj "/CN=${org} Test Root CA/O=${org}" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash"

openssl genrsa -out "${output_dir}/tls.key" "${tls_bits}"
openssl req -new \
  -key "${output_dir}/tls.key" \
  -out "${output_dir}/tls.csr" \
  -subj "/CN=*.${domain}/O=${org}"

openssl x509 -req \
  -in "${output_dir}/tls.csr" \
  -CA "${output_dir}/ca.crt" \
  -CAkey "${output_dir}/ca.key" \
  -CAcreateserial \
  -out "${output_dir}/tls.crt" \
  -days "${tls_days}" \
  -sha256 \
  -extfile "${output_dir}/tls.ext"

echo "Generated certificates in ${output_dir}"
openssl x509 -in "${output_dir}/tls.crt" -noout -subject -issuer -ext subjectAltName
