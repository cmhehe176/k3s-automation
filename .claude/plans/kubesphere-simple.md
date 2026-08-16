# KubeSphere on K3s - Simple Plan

## 🎯 What You Get

**KubeSphere** = Beautiful Web Console + Monitoring + Logging

- 🖥️ Modern GUI (way better than K8s dashboard)
- 📊 Built-in monitoring (Prometheus + Grafana)
- 📝 Logging (ELK stack included)
- 🚀 Optional: DevOps (Jenkins CI/CD)

## 📋 Resources

**Minimal** (Console only): +4GB RAM, +20GB storage
**Full** (+ Logging): +8GB RAM, +200GB storage

→ Bạn có 2TB, không lo storage! 

## 🚀 Quick Install

### Step 1: Deploy Minimal

```bash
# Download installer
kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/kubesphere-installer.yaml
kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/cluster-configuration.yaml

# Watch installation (~15 minutes)
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l 'app in (ks-install, ks-installer)' -o jsonpath='{.items[0].metadata.name}') -f
```

### Step 2: Get Console URL

```bash
kubectl get svc ks-console -n kubesphere-system
# Open: http://<IP>:30880
# Login: admin / P@88w0rd
```

### Step 3: Enable Logging (Optional)

In KubeSphere Console:
1. Platform → Cluster Management
2. System Components → Logging
3. Enable → Install
4. Wait ~10 minutes

Or via CLI:
```bash
kubectl edit clusterconfiguration ks-installer -n kubesphere-system
# Change logging.enabled: false → true
```

## 📦 Ansible Structure

```
ansible/kubesphere/
├── playbooks/
│   └── deploy.yml
└── scripts/
    └── deploy-kubesphere.sh
```

**deploy.yml**:
```yaml
---
- name: Deploy KubeSphere
  hosts: k3s_control[0]
  tasks:
    - name: Install KubeSphere
      shell: |
        kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/kubesphere-installer.yaml
        kubectl apply -f https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/cluster-configuration.yaml
      
    - name: Wait for installation
      shell: kubectl logs -n kubesphere-system -l app=ks-installer -f
      async: 1800
      poll: 0
      
    - name: Get console info
      shell: kubectl get svc ks-console -n kubesphere-system
      register: console
      
    - debug:
        msg: "Console: http://{{ console.stdout }}"
```

**deploy-kubesphere.sh**:
```bash
#!/bin/bash
cd ansible/
ansible-playbook kubesphere/playbooks/deploy.yml
echo "Login: admin / P@88w0rd"
```

## ⚙️ Storage Config

Edit cluster-configuration before apply:
```yaml
persistence:
  storageClass: "longhorn"  # Your storage

logging:
  enabled: true  # Enable from start
  elasticsearch:
    elasticsearchDataVolumeSize: 200Gi  # Plenty!
    logMaxAge: 30  # Keep 30 days
```

## ✅ Done!

That's it. KubeSphere handles everything else automatically.

**Timeline**: 
- Deploy: 15 minutes
- Enable logging: +10 minutes
- Total: ~25 minutes

**Access**:
- Console: MetalLB IP:30880
- Username: `admin`
- Password: `P@88w0rd` (change after login)
