# Vault Configuration Reference

## Basic Configuration
```hcl
disable_mlock = true
ui = true

listener "tcp" {
  address = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable = 1
  tls_disable_client_certs = true
}

storage "raft" {
  path = "/vault/data"
  node_id = "vault-0"
  retry_join {
    leader_api_addr = "http://vault-0.vault-internal:8200"
  }
  retry_join {
    leader_api_addr = "http://vault-1.vault-internal:8200"
  }
  retry_join {
    leader_api_addr = "http://vault-2.vault-internal:8200"
  }
}

api_addr = "http://127.0.0.1:8200"
cluster_addr = "http://127.0.0.1:8201"

service_registration "kubernetes" {}
```

## Authentication Configuration
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host="https://A2327B7CEE41B71FC41B598791CA6057.gr7.us-west-2.eks.amazonaws.com" \
    token_reviewer_jwt="<service-account-token>" \
    kubernetes_ca_cert=@/tmp/ca.crt

# Create app policy
vault policy write app - <<EOF
path "secret/data/app/*" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes role
vault write auth/kubernetes/role/app \
    bound_service_account_names=* \
    bound_service_account_namespaces=* \
    policies=app \
    ttl=1h
```

## Secrets Engine Configuration
```bash
# Enable KV-v2 secrets engine
vault secrets enable -path=secret kv-v2

# Example secret
vault kv put secret/app/test \
    username=testuser \
    password=testpass
```

## Service Account Configuration
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: vault

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: vault

---
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-secret
  namespace: vault
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
```

## Important Notes
1. The configuration uses HTTP for simplicity. For production, enable TLS.
2. The service account has broad permissions. Consider restricting in production.
3. The TTL for tokens is set to 1h. Adjust based on security requirements.
4. Store root token and unseal keys securely in production. 