```bash
scripts/generate-certs.sh ejempo.com generated-ejempo-certs
```

```bash
TLS_CERT="$(cat generated-ejemplo-certs/tls.crt generated-ejemplo-certs/ca.crt | base64 | tr -d '\n')"
TLS_KEY="$(base64 < generated-ejemplo-certs/tls.key | tr -d '\n')"
CA_BUNDLE_CERTS="$(base64 < generated-ejemplo-certs/ca.crt | tr -d '\n')"

uds deploy k3d-core-demo:latest \
  --confirm \
  --set DOMAIN=ejemplo.com \
  --set ADMIN_DOMAIN=admin.ejemplo.com \
  --set ADMIN_TLS_CERT="${TLS_CERT}" \
  --set ADMIN_TLS_KEY="${TLS_KEY}" \
  --set TENANT_TLS_CERT="${TLS_CERT}" \
  --set TENANT_TLS_KEY="${TLS_KEY}" \
  --set CA_BUNDLE_CERTS="${CA_BUNDLE_CERTS}" \
  --set CA_BUNDLE_INCLUDE_PUBLIC_CERTS=true
```