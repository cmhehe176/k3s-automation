# KubeSphere on K3s - Simple Plan

## 🎯 What You Get

**KubeSphere** = Beautiful Web Console + Monitoring + Logging

- 🖥️ Modern GUI (way better than K8s dashboard)
- 📊 Built-in monitoring (Prometheus + Grafana)
- 📝 Logging (ELK stack included)
- 🚀 Optional: DevOps (Jenkins CI/CD)

## 📋 Resources (4GB RAM Limit)

**Config for 4GB total system RAM:**
- KubeSphere core: 2GB
- Monitoring (lightweight): 1GB
- Buffer: 1GB

**Skip logging initially** - Elasticsearch needs 2GB+

→ Install minimal first, enable logging later if needed

## 💾 Storage

- KubeSphere system: 20GB
- Monitoring (Prometheus): 20GB
- Total: 40GB (you have 2TB, no problem!)

## ⚙️ Lightweight Configuration

Edit `cluster-configuration.yaml` **before** applying:

```yaml
apiVersion: installer.kubesphere.io/v1alpha1
kind: ClusterConfiguration
metadata:
  name: ks-installer
  namespace: kubesphere-system
spec:
  persistence:
    storageClass: "longhorn"
  
  # Core components - lightweight
  console:
    enableMultiLogin: true
    port: 30880
  
  # Monitoring - minimal
  monitoring:
    storageClass: "longhorn"
    prometheusMemoryRequest: 400Mi  # Reduced from 2Gi
    prometheusVolumeSize: 10Gi
    prometheusReplicas: 1
  
  # Metrics server - keep
  metrics_server:
    enabled: true
  
  # DISABLE heavy components
  alerting:
    enabled: false
  auditing:
    enabled: false
  devops:
    enabled: false  # Skip Jenkins (needs 2GB+)
  events:
    enabled: false
  logging:
    enabled: false  # Skip ELK (needs 4GB+)
  openpitrix:
    store:
      enabled: false
  servicemesh:
    enabled: false  # Skip Istio
  network:
    networkpolicy:
      enabled: false
    ippool:
      type: none
``` 

## 🚀 Quick Install

### Step 1: Download and Edit Config

```bash
# Download files
wget https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/kubesphere-installer.yaml
wget https://github.com/kubesphere/ks-installer/releases/download/v3.4.1/cluster-configuration.yaml

# Edit cluster-configuration.yaml
nano cluster-configuration.yaml
# Set prometheusMemoryRequest: 400Mi
# Set logging.enabled: false
# Set devops.enabled: false
# Set storageClass: "longhorn"

# Apply
kubectl apply -f kubesphere-installer.yaml
kubectl apply -f cluster-configuration.yaml
```

# Watch installation (~15 minutes)
kubectl logs -n kubesphere-system $(kubectl get pod -n kubesphere-system -l 'app in (ks-install, ks-installer)' -o jsonpath='{.items[0].metadata.name}') -f
```

### Step 2: Get Console URL

```bash
kubectl get svc ks-console -n kubesphere-system
# Open: http://<IP>:30880
# Login: admin / P@88w0rd
```

### Step 3: Monitor Resources

```bash
# Check RAM usage
kubectl top nodes
kubectl top pods -A

# If RAM > 3.5GB, consider:
# 1. Remove ArgoCD temporarily
# 2. Reduce Prometheus further
# 3. Skip logging entirely
```

### Step 4: (Optional) Enable Logging Later

**Only if you add more RAM!**

Logging (ELK) needs +4GB RAM minimum.

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
