# KubeSphere on K3s - Simple Plan

## 🎯 What You Get

**KubeSphere** = Beautiful Web Console + Monitoring + Logging

- 🖥️ Modern GUI (way better than K8s dashboard)
- 📊 Built-in monitoring (Prometheus + Grafana)
- 📝 Logging (ELK stack included)
- 🚀 Optional: DevOps (Jenkins CI/CD)

## 📋 Resources (Focus on Kibana/Logging)

**Your Priority**: Kibana for log analysis

**KubeSphere Limit**: 4GB total
- Core: ~500MB
- **Elasticsearch + Kibana**: ~2.5GB ⭐ (main focus)
- Prometheus (minimal): ~800MB (keep for basic metrics)
- Buffer: ~200MB

**Storage**:
- Logging (ES): 200GB (30 days logs)
- Prometheus: 10GB (7 days metrics)
- Total: 210GB

## ⚙️ Configuration (Kibana-focused)

```yaml
apiVersion: installer.kubesphere.io/v1alpha1
kind: ClusterConfiguration
metadata:
  name: ks-installer
  namespace: kubesphere-system
spec:
  persistence:
    storageClass: "longhorn"
  
  # Monitoring - MINIMAL (just for basic health)
  monitoring:
    storageClass: "longhorn"
    prometheusMemoryRequest: 400Mi
    prometheusMemoryLimit: 800Mi     # Keep small
    prometheusVolumeSize: 10Gi
    prometheusReplicas: 1
    node_exporter:
      enabled: true                   # Node metrics
    kube_state_metrics:
      enabled: true                   # Basic K8s metrics
    # Disable heavy exporters
    alerting:
      enabled: false
  
  # Logging - FULL ENABLE ⭐ (Elasticsearch + Kibana)
  logging:
    enabled: true                     # ⭐ Main feature
    logsidecar:
      enabled: true
      replicas: 2
    elasticsearch:
      elasticsearchMasterReplicas: 1
      elasticsearchDataReplicas: 1
      elasticsearchMasterVolumeSize: 10Gi
      elasticsearchDataVolumeSize: 200Gi  # 200GB for logs
      logMaxAge: 30                   # Keep 30 days
      elkPrefix: logstash
      # ES resource limits
      elasticsearchJavaOpts: "-Xms1g -Xmx1g"  # 1GB heap
      resources:
        limits:
          cpu: 1
          memory: 2Gi               # ES max 2GB
        requests:
          cpu: 500m
          memory: 1Gi
  
  # Keep minimal
  alerting:
    enabled: false                    # No alerts needed
  auditing:
    enabled: false
  devops:
    enabled: false
  events:
    enabled: true                     # K8s events for context
  metrics_server:
    enabled: true                     # Basic metrics
  openpitrix:
    store:
      enabled: false
  servicemesh:
    enabled: false
```

**Result**: 
- ✅ Kibana accessible in KubeSphere Console
- ✅ Log search across all pods
- ✅ Log analysis & filtering
- ✅ Log export
- ✅ Basic metrics (bonus) 

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

## 🔍 Access Kibana in KubeSphere

After installation:

1. **Login to KubeSphere Console**: `http://<IP>:30880`
2. **Navigate**: Toolbox → Log Search (left sidebar)
3. **You'll see**:
   - 🔍 Search bar with query syntax
   - 📊 Log histogram (time distribution)
   - 📝 Log entries from all pods
   - 🎯 Filters (namespace, pod, container)
   - 📤 Export logs

**Search Examples**:
```
# All errors
level:error

# Specific pod
kubernetes.pod_name:my-app*

# Time range + keyword
@timestamp:[now-1h TO now] AND "connection refused"

# Namespace filter
kubernetes.namespace_name:default AND message:*timeout*
```

## 📊 Monitoring vs Logging

**Prometheus** (kept minimal):
- View in: Platform → Clusters → Monitoring
- Shows: CPU, RAM graphs
- Use for: Quick health check

**Kibana** (main focus):
- View in: Toolbox → Log Search
- Shows: All application logs
- Use for: Debugging, troubleshooting, analysis

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
