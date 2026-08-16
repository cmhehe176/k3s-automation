# KubeSphere on K3s - Simple Plan

## 🎯 What You Get

**KubeSphere** = Beautiful Web Console + Monitoring + Logging

- 🖥️ Modern GUI (way better than K8s dashboard)
- 📊 Built-in monitoring (Prometheus + Grafana)
- 📝 Logging (ELK stack included)
- 🚀 Optional: DevOps (Jenkins CI/CD)

## 📋 Resources

**Your Setup**: Node has 32GB RAM, plenty!

**KubeSphere Limit**: Set to use only **4GB max**
- Core components: ~800MB
- Monitoring (Prometheus): ~1GB
- Logging (ELK): ~2GB
- Buffer: ~200MB

**Why limit**: Reserve RAM for other apps/services

**Storage**: 
- KubeSphere: 50GB
- Logging (30 days): 200GB
- You have 2TB, no problem!

## ⚙️ Configuration (4GB Resource Limit)

```yaml
apiVersion: installer.kubesphere.io/v1alpha1
kind: ClusterConfiguration
metadata:
  name: ks-installer
  namespace: kubesphere-system
spec:
  persistence:
    storageClass: "longhorn"
  
  # Monitoring - with resource limits
  monitoring:
    storageClass: "longhorn"
    prometheusMemoryRequest: 800Mi
    prometheusMemoryLimit: 1Gi      # Limit to 1GB
    prometheusVolumeSize: 20Gi
    prometheusReplicas: 1
  
  # Logging - with resource limits
  logging:
    enabled: true  # Enable with limits
    logsidecar:
      enabled: true
      replicas: 1
    elasticsearch:
      elasticsearchMasterReplicas: 1
      elasticsearchDataReplicas: 1
      elasticsearchMasterVolumeSize: 10Gi
      elasticsearchDataVolumeSize: 200Gi
      logMaxAge: 30  # 30 days retention
      # Resource limits for ES
      elasticsearchJavaOpts: "-Xms1g -Xmx1g"  # 1GB heap
      resources:
        limits:
          memory: 2Gi  # ES max 2GB
        requests:
          memory: 1Gi
  
  # Keep other components minimal
  alerting:
    enabled: false
  auditing:
    enabled: false
  devops:
    enabled: false  # Add later if needed
  events:
    enabled: true
  metrics_server:
    enabled: true
  openpitrix:
    store:
      enabled: false
  servicemesh:
    enabled: false
```

**Total KubeSphere**: ~4GB RAM, 250GB storage 

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

### Step 3: Verify Resource Usage

```bash
# Check KubeSphere pods RAM usage
kubectl top pods -n kubesphere-system
kubectl top pods -n kubesphere-logging-system

# Should see:
# - ks-* pods: ~800MB total
# - elasticsearch: ~1.5GB
# - prometheus: ~800MB
# Total: ~3-4GB
```

### Step 4: Access Console

Open browser: `http://<MetalLB-IP>:30880`

**Login**: admin / P@88w0rd

**You'll see**:
- ✅ Cluster overview dashboard
- ✅ Workload management
- ✅ Monitoring charts (CPU, RAM, disk)
- ✅ Log search & analysis (if enabled)
- ✅ User & RBAC management

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
