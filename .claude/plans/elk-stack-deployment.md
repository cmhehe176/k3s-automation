# Implementation Plan: ELK Stack Deployment on K3s

## 🎯 Objective

Deploy ELK Stack (Elasticsearch, Logstash, Kibana) on K3s cluster for centralized logging and monitoring, following the existing ansible structure.

---

## 📊 What is ELK Stack?

**ELK = Elasticsearch + Logstash + Kibana**

- **Elasticsearch**: Search and analytics engine (stores logs)
- **Logstash**: Log processing pipeline (collects & transforms logs)
- **Kibana**: Visualization dashboard (view & analyze logs)

**Modern Stack**: ELK often includes **Filebeat** (lightweight log shipper)

**Use Cases**:
- Centralized logging from all K3s pods
- Application log analysis
- System metrics monitoring
- Security audit logs
- Performance troubleshooting

---

## 🏗️ Architecture

### Deployment Strategy

**Option A: Full ELK Stack** (Recommended for production)
```
K3s Pods → Filebeat → Logstash → Elasticsearch → Kibana
```

**Option B: EFK Stack** (Lighter alternative)
```
K3s Pods → Fluentd → Elasticsearch → Kibana
```
- Replace Logstash with Fluentd (lighter, less features)

**Option C: Elastic Cloud on Kubernetes (ECK)** ⭐ **RECOMMENDED**
```
Elastic Operator → Manages ES, Kibana, Beats automatically
```
- Official Elastic operator
- Easier management
- Auto-scaling
- Built-in monitoring

---

## 📋 Resource Requirements

### ⭐ Ultra-Lightweight Config (K3s Optimized)

**Elasticsearch** (single node):
- 1 vCPU, 1.5GB RAM, **100GB storage** (generous for logs!)
- JVM heap: 768MB (minimum safe)

**Kibana**:
- 0.5 vCPU, 512MB RAM

**Skip Logstash** (use Filebeat direct → ES):
- Saves 2GB RAM!

**Filebeat** (per node):
- 0.1 vCPU, 64MB RAM

**Total**: ~2 vCPUs, **2GB RAM** total! 🎉

### Standard Development (if you have more RAM)

**Elasticsearch**: 2 vCPUs, 4GB RAM, 20GB storage
**Kibana**: 1 vCPU, 2GB RAM
**Filebeat**: 0.1 vCPU, 128MB RAM

**Total**: ~3-4 vCPUs, 6-8GB RAM

### Production (3-node Elasticsearch cluster)

- Elasticsearch: 3 nodes × (4 vCPUs, 8GB RAM, 100GB storage)
- Kibana: 2 replicas × (1 vCPU, 2GB RAM)
- Logstash: 2 replicas × (2 vCPUs, 4GB RAM)
- Filebeat: DaemonSet on all nodes

**Total**: ~20+ vCPUs, 40+ GB RAM

**Note**: We'll start with **lightweight dev setup** suitable for K3s.

---

## 🎨 Implementation Approach

### Phase 1: Create ELK Directory Structure

**Goal**: Add `elk/` to ansible structure

**Tasks**:
```bash
mkdir -p ansible/elk/{playbooks,roles,scripts}
mkdir -p ansible/elk/roles/elk-operator
```

**Update ansible.cfg**:
```ini
[defaults]
roles_path = k3s/roles:argocd/roles:elk/roles
```

**Structure**:
```
ansible/elk/
├── playbooks/
│   ├── deploy.yml
│   └── uninstall.yml
├── roles/
│   └── elk-operator/
│       ├── tasks/
│       ├── templates/
│       └── defaults/
└── scripts/
    ├── deploy-elk.sh
    ├── uninstall-elk.sh
    └── README.md
```

### Phase 2: Deploy ECK Operator

**Goal**: Install Elastic Cloud on Kubernetes operator

**Why ECK**: 
- Official Elastic operator
- Manages Elasticsearch, Kibana, Beats lifecycle
- Handles upgrades, scaling, monitoring

**Playbook**: `ansible/elk/playbooks/deploy.yml`

**Tasks**:
1. Install ECK CRDs
2. Deploy ECK operator
3. Wait for operator ready

**Commands**:
```bash
# Install ECK CRDs
kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml

# Install ECK operator
kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
```

**Why**: ECK operator automates ES cluster management.

### Phase 3: Deploy Elasticsearch Cluster

**Goal**: Create lightweight Elasticsearch instance

**Manifest**: `ansible/elk/roles/elk-operator/templates/elasticsearch.yaml.j2`

**Configuration** (Ultra-Lightweight):
```yaml
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elk-cluster
  namespace: elastic-system
spec:
  version: 8.15.0
  nodeSets:
  - name: default
    count: 1  # Single node
    config:
      node.store.allow_mmap: false  # K3s compatibility
      # Reduce resource usage
      indices.memory.index_buffer_size: 10%
      http.max_content_length: 50mb
    volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 100Gi  # Plenty for logs!
        storageClassName: longhorn
    podTemplate:
      spec:
        containers:
        - name: elasticsearch
          resources:
            requests:
              memory: 768Mi  # Ultra-lightweight!
              cpu: 500m
            limits:
              memory: 1536Mi  # 1.5GB max
              cpu: 1
          env:
          - name: ES_JAVA_OPTS
            value: "-Xms768m -Xmx768m"  # Minimal JVM heap
          - name: xpack.security.enabled
            value: "true"
          - name: xpack.security.http.ssl.enabled
            value: "false"  # Disable SSL to save memory
```

**Alternative** (If you have 4GB+ RAM):
```yaml
# Just change resources:
resources:
  requests:
    memory: 2Gi
    cpu: 1
  limits:
    memory: 4Gi
    cpu: 2
env:
- name: ES_JAVA_OPTS
  value: "-Xms2g -Xmx2g"
```

**Key Points**:
- Single node for development
- 10GB storage on Longhorn
- 2GB JVM heap (adjust based on available RAM)
- `node.store.allow_mmap: false` for K3s compatibility

**How to apply**: Ansible template → kubectl apply

### Phase 4: Deploy Kibana

**Goal**: Web UI for log visualization

**Manifest**: `ansible/elk/roles/elk-operator/templates/kibana.yaml.j2`

**Configuration**:
```yaml
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: elastic-system
spec:
  version: 8.15.0
  count: 1
  elasticsearchRef:
    name: elk-cluster
  podTemplate:
    spec:
      containers:
      - name: kibana
        resources:
          requests:
            memory: 512Mi  # Ultra-lightweight!
            cpu: 200m
          limits:
            memory: 1Gi
            cpu: 500m
        env:
        - name: NODE_OPTIONS
          value: "--max-old-space-size=512"  # Limit Node.js memory
  http:
    service:
      spec:
        type: LoadBalancer  # MetalLB assigns external IP
```

**Access**:
- MetalLB assigns external IP
- Default user: `elastic`
- Password: Auto-generated (retrieve from secret)

### Phase 5: Deploy Filebeat (Log Shipper)

**Goal**: Collect logs from all K3s pods

**Manifest**: `ansible/elk/roles/elk-operator/templates/filebeat.yaml.j2`

**Configuration**:
```yaml
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: filebeat
  namespace: elastic-system
spec:
  type: filebeat
  version: 8.15.0
  elasticsearchRef:
    name: elk-cluster
  config:
    filebeat.autodiscover:
      providers:
      - type: kubernetes
        node: ${NODE_NAME}
        hints.enabled: true
        hints.default_config:
          type: container
          paths:
          - /var/log/containers/*${data.kubernetes.container.id}.log
    processors:
    - add_cloud_metadata: {}
    - add_host_metadata: {}
  daemonSet:
    podTemplate:
      spec:
        serviceAccountName: filebeat
        automountServiceAccountToken: true
        terminationGracePeriodSeconds: 30
        dnsPolicy: ClusterFirstWithHostNet
        hostNetwork: true
        containers:
        - name: filebeat
          securityContext:
            runAsUser: 0
          volumeMounts:
          - name: varlogcontainers
            mountPath: /var/log/containers
          - name: varlogpods
            mountPath: /var/log/pods
          - name: varlibdockercontainers
            mountPath: /var/lib/docker/containers
          resources:
            requests:
              memory: 128Mi
              cpu: 100m
            limits:
              memory: 256Mi
              cpu: 200m
        volumes:
        - name: varlogcontainers
          hostPath:
            path: /var/log/containers
        - name: varlogpods
          hostPath:
            path: /var/log/pods
        - name: varlibdockercontainers
          hostPath:
            path: /var/lib/docker/containers
```

**Key Points**:
- DaemonSet (runs on every node)
- Auto-discovers K3s pods
- Ships logs to Elasticsearch
- Minimal resource footprint

### Phase 6: Configure RBAC & ServiceAccount

**Goal**: Allow Filebeat to read pod logs

**Manifest**: `ansible/elk/roles/elk-operator/templates/filebeat-rbac.yaml.j2`

**Configuration**:
```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: filebeat
  namespace: elastic-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: filebeat
rules:
- apiGroups: [""]
  resources:
  - namespaces
  - pods
  - nodes
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources:
  - replicasets
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: filebeat
subjects:
- kind: ServiceAccount
  name: filebeat
  namespace: elastic-system
roleRef:
  kind: ClusterRole
  name: filebeat
  apiGroup: rbac.authorization.k8s.io
```

### Phase 7: Create Management Scripts

**Goal**: Easy deployment & management

**Script**: `ansible/elk/scripts/deploy-elk.sh`

```bash
#!/bin/bash
set -e

cd ansible/

echo "🚀 Deploying ELK Stack..."
ansible-playbook elk/playbooks/deploy.yml

echo ""
echo "✅ ELK Stack deployed!"
echo ""
echo "📊 Get Kibana URL:"
echo "   kubectl get svc kibana-kb-http -n elastic-system"
echo ""
echo "🔑 Get elastic user password:"
echo "   kubectl get secret elk-cluster-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d"
echo ""
```

**Script**: `ansible/elk/scripts/uninstall-elk.sh`

```bash
#!/bin/bash
set -e

cd ansible/

echo "⚠️  WARNING: This will remove ELK Stack and ALL logs!"
read -p "Continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled"
    exit 0
fi

ansible-playbook elk/playbooks/uninstall.yml
```

---

## 📝 Detailed Playbook Structure

### `ansible/elk/playbooks/deploy.yml`

```yaml
---
- name: Deploy ELK Stack on K3s
  hosts: k3s_control[0]
  gather_facts: no

  tasks:
    - name: Create elastic-system namespace
      command: kubectl create namespace elastic-system --dry-run=client -o yaml | kubectl apply -f -
      changed_when: true

    - name: Install ECK CRDs
      command: kubectl create -f https://download.elastic.co/downloads/eck/2.14.0/crds.yaml
      changed_when: true
      ignore_errors: yes

    - name: Install ECK Operator
      command: kubectl apply -f https://download.elastic.co/downloads/eck/2.14.0/operator.yaml
      changed_when: true

    - name: Wait for ECK operator ready
      command: kubectl wait --namespace elastic-system --for=condition=ready pod --selector=control-plane=elastic-operator --timeout=300s
      register: wait_result
      retries: 3
      delay: 10
      until: wait_result.rc == 0
      changed_when: false

    - name: Apply Elasticsearch manifest
      kubernetes.core.k8s:
        state: present
        template: elasticsearch.yaml.j2
        namespace: elastic-system

    - name: Wait for Elasticsearch cluster ready
      command: kubectl wait --namespace elastic-system --for=condition=ready pod --selector=elasticsearch.k8s.elastic.co/cluster-name=elk-cluster --timeout=600s
      register: es_wait
      retries: 3
      delay: 30
      until: es_wait.rc == 0
      changed_when: false

    - name: Apply Kibana manifest
      kubernetes.core.k8s:
        state: present
        template: kibana.yaml.j2
        namespace: elastic-system

    - name: Wait for Kibana ready
      command: kubectl wait --namespace elastic-system --for=condition=ready pod --selector=kibana.k8s.elastic.co/name=kibana --timeout=300s
      register: kb_wait
      retries: 2
      delay: 30
      until: kb_wait.rc == 0
      changed_when: false

    - name: Apply Filebeat RBAC
      kubernetes.core.k8s:
        state: present
        template: filebeat-rbac.yaml.j2

    - name: Apply Filebeat manifest
      kubernetes.core.k8s:
        state: present
        template: filebeat.yaml.j2
        namespace: elastic-system

    - name: Get Kibana LoadBalancer IP
      command: kubectl get svc kibana-kb-http -n elastic-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
      register: kibana_ip
      changed_when: false

    - name: Get elastic user password
      command: kubectl get secret elk-cluster-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}'
      register: elastic_password_b64
      changed_when: false

    - name: Decode password
      set_fact:
        elastic_password: "{{ elastic_password_b64.stdout | b64decode }}"

    - name: Display access information
      debug:
        msg:
          - "✅ ELK Stack deployed successfully!"
          - ""
          - "Kibana URL: https://{{ kibana_ip.stdout }}:5601"
          - "Username: elastic"
          - "Password: {{ elastic_password }}"
          - ""
          - "⚠️  Note: Certificate is self-signed, accept in browser"
```

---

## 🧪 Verification Steps

### After Deployment

```bash
# Check ECK operator
kubectl get pods -n elastic-system | grep elastic-operator

# Check Elasticsearch
kubectl get elasticsearch -n elastic-system
kubectl get pods -n elastic-system | grep elk-cluster

# Check Kibana
kubectl get kibana -n elastic-system
kubectl get svc kibana-kb-http -n elastic-system

# Check Filebeat
kubectl get beat -n elastic-system
kubectl get pods -n elastic-system | grep filebeat

# Get Kibana URL
kubectl get svc kibana-kb-http -n elastic-system

# Get elastic password
kubectl get secret elk-cluster-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d
```

### Access Kibana

1. Get LoadBalancer IP from MetalLB
2. Open browser: `https://<KIBANA_IP>:5601`
3. Login with `elastic` user and retrieved password
4. Accept self-signed certificate

### Verify Log Collection

1. In Kibana → Discover
2. Create index pattern: `filebeat-*`
3. View K3s pod logs in real-time

---

## ⚠️ Challenges & Solutions

| Challenge | Solution |
|-----------|----------|
| High memory usage | Start with 1-node ES, 2GB heap |
| Storage requirements | Use Longhorn PVC, 10GB initial |
| Self-signed certificates | Accept in browser or configure cert-manager |
| Slow startup | ES takes 2-5 minutes to start |
| mmap not available | Set `node.store.allow_mmap: false` |

---

## 📊 Comparison: Lightweight vs Full Stack

| Component | Lightweight (Dev) | Full Stack (Prod) |
|-----------|-------------------|-------------------|
| **Elasticsearch** | 1 node, 2GB heap | 3 nodes, 8GB heap each |
| **Kibana** | 1 replica | 2 replicas |
| **Logstash** | Skip (Filebeat direct) | 2 replicas |
| **Filebeat** | DaemonSet | DaemonSet |
| **Total RAM** | ~6GB | ~40GB+ |
| **Total Storage** | 10GB | 300GB+ |

**Recommendation**: Start with lightweight, scale up as needed.

---

## 🎯 Success Criteria

- [ ] `elastic-system` namespace created
- [ ] ECK operator running
- [ ] Elasticsearch cluster healthy (green status)
- [ ] Kibana accessible via LoadBalancer IP
- [ ] Filebeat DaemonSet running on all nodes
- [ ] Logs visible in Kibana Discover
- [ ] Scripts working from `ansible/` directory
- [ ] Documentation complete in `elk/scripts/README.md`

---

## 💡 Next Steps After Deployment

1. **Create Index Patterns** in Kibana for `filebeat-*`
2. **Setup Dashboards** for common queries
3. **Configure Alerts** for error patterns
4. **Add Metricbeat** for system metrics (optional)
5. **Setup Retention Policy** to manage storage
6. **Configure Backups** for Elasticsearch snapshots

---

## 🔮 Optional Enhancements

### Add Metricbeat (System Metrics)

```yaml
apiVersion: beat.k8s.elastic.co/v1beta1
kind: Beat
metadata:
  name: metricbeat
spec:
  type: metricbeat
  version: 8.15.0
  elasticsearchRef:
    name: elk-cluster
  config:
    metricbeat.modules:
    - module: kubernetes
      metricsets: [pod, container, node, system]
```

### Add APM Server (Application Tracing)

```yaml
apiVersion: apm.k8s.elastic.co/v1
kind: ApmServer
metadata:
  name: apm-server
spec:
  version: 8.15.0
  count: 1
  elasticsearchRef:
    name: elk-cluster
```

### Setup Index Lifecycle Management

```bash
# Auto-delete old logs after 7 days
PUT _ilm/policy/filebeat-policy
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "5GB"
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}
```

---

## 📚 Documentation Structure

Create `ansible/elk/scripts/README.md`:
- Prerequisites
- Architecture diagram
- Deployment steps
- Accessing Kibana
- Common queries
- Troubleshooting

---

## 🚀 Quick Start Summary

```bash
# 1. Deploy ELK
cd ansible/
./elk/scripts/deploy-elk.sh

# 2. Get access info
kubectl get svc kibana-kb-http -n elastic-system
kubectl get secret elk-cluster-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 -d

# 3. Open Kibana in browser
# Login with elastic/<password>

# 4. Create index pattern: filebeat-*
# View logs in Discover tab
```

---

**Estimated Time**: 
- Setup: 1-2 hours
- ES startup: 5-10 minutes
- Total: ~2-3 hours first time

**Ready to proceed?**
- Shall I create the elk/ directory structure?
- Start with lightweight (6GB RAM) or full stack?
- Need Logstash or just Filebeat → Elasticsearch?
