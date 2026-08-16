# 🔒 Security Best Practices cho K3s Cluster

## 1. K3s Token Security

### Cách 1: Environment Variable (Recommended cho dev/test)
```bash
# Generate secure token
export K3S_TOKEN=$(openssl rand -base64 32)

# Run Ansible
cd ansible/
./bootstrap.sh
```

### Cách 2: Ansible Vault (Recommended cho production)
```bash
# Encrypt token
ansible-vault create inventory/group_vars/vault.yml

# Nội dung vault.yml:
vault_k3s_token: "your-super-secret-token-here"

# Update all.yml để reference vault
k3s_token: "{{ vault_k3s_token }}"

# Run với vault password
ansible-playbook playbooks/01-k3s-control.yml --ask-vault-pass
```

### Cách 3: External Secrets (Enterprise)
```bash
# Dùng HashiCorp Vault hoặc AWS Secrets Manager
k3s_token: "{{ lookup('aws_ssm', '/k3s/cluster/token') }}"
```

---

## 2. Kubeconfig Security

**File hiện tại:** `~/.kube/config-k3s`

### Bảo vệ kubeconfig:
```bash
# Set permissions
chmod 600 ~/.kube/config-k3s

# Không commit vào Git
echo "config-k3s" >> ~/.gitignore

# Rotate token định kỳ (mỗi 90 ngày)
```

---

## 3. SSH Key Management

### Setup SSH Agent:
```bash
# Add key vào agent
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa

# Ansible sẽ dùng agent thay vì password
```

### SSH Hardening trên nodes:
```bash
# Disable password auth (chỉ dùng keys)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Disable root login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
```

---

## 4. Network Security

### Firewall Rules (ufw)
```bash
# Trên Node-1 (Control Plane)
sudo ufw allow 6443/tcp      # K8s API
sudo ufw allow 10250/tcp     # Kubelet
sudo ufw allow from 192.168.1.0/24  # Internal network

# Trên Node-2, Node-3 (Workers)
sudo ufw allow from 192.168.1.10  # Chỉ từ control plane
sudo ufw allow 10250/tcp           # Kubelet
```

### Network Policies
```yaml
# Deny all by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

---

## 5. RBAC Configuration

### Tạo ServiceAccount cho applications:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-deployer
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-deployer-role
  namespace: production
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-deployer-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-deployer
roleRef:
  kind: Role
  name: app-deployer-role
  apiGroup: rbac.authorization.k8s.io
```

---

## 6. Secrets Management

### Sealed Secrets (Recommended)
```bash
# Cài Sealed Secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Encrypt secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# Commit sealed-secret.yaml vào Git (safe!)
```

### Example:
```bash
# Original secret (KHÔNG commit vào Git)
kubectl create secret generic db-password \
  --from-literal=password=supersecret123 \
  --dry-run=client -o yaml > secret.yaml

# Encrypt
kubeseal < secret.yaml > sealed-secret.yaml

# Deploy
kubectl apply -f sealed-secret.yaml
```

---

## 7. Audit Logging

### Enable K3s Audit Log:
```yaml
# /etc/rancher/k3s/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  omitStages:
  - RequestReceived
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
```

```bash
# Restart K3s với audit enabled
sudo systemctl edit k3s
# Thêm: --kube-apiserver-arg=audit-log-path=/var/log/k3s-audit.log
sudo systemctl restart k3s
```

---

## 8. Node Security

### Automatic Security Updates:
```bash
# Cài unattended-upgrades
sudo apt install unattended-upgrades

# Enable
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### SELinux/AppArmor:
```bash
# Check AppArmor status
sudo aa-status

# K3s sẽ tự động dùng AppArmor profiles
```

---

## 9. Backup Encryption

### Encrypt backups:
```bash
# Backup với encryption
tar czf - /var/lib/rancher/k3s | \
  openssl enc -aes-256-cbc -salt -pbkdf2 -out k3s-backup.tar.gz.enc

# Restore
openssl enc -d -aes-256-cbc -pbkdf2 -in k3s-backup.tar.gz.enc | \
  tar xzf - -C /
```

---

## 10. Monitoring & Alerting

### Falco (Runtime Security)
```bash
# Cài Falco để detect malicious behavior
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco-system --create-namespace
```

### Alerts:
```yaml
# Alert khi có pod exec
- rule: Terminal Shell in Container
  desc: Detect shell execution in containers
  condition: >
    spawned_process and container and 
    shell_procs and proc.tty != 0
  output: "Shell spawned in container (user=%user.name container=%container.name)"
  priority: WARNING
```

---

## 📋 Security Checklist

**Before Production:**
- [ ] K3s token dùng Ansible Vault hoặc env var
- [ ] SSH password auth disabled
- [ ] Firewall rules configured
- [ ] RBAC policies defined
- [ ] Secrets dùng Sealed Secrets
- [ ] Network policies enabled
- [ ] Audit logging enabled
- [ ] Automatic security updates enabled
- [ ] Backup encryption enabled
- [ ] Monitoring & alerting configured

**Monthly:**
- [ ] Review audit logs
- [ ] Rotate K3s token
- [ ] Update K3s version
- [ ] Review RBAC permissions
- [ ] Test backup restore

**Quarterly:**
- [ ] Penetration testing
- [ ] Review firewall rules
- [ ] Audit user access

---

**Created**: 2026-08-16  
**Last Updated**: 2026-08-16  
**Owner**: Security Team
