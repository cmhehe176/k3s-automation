# ==============================================================================
#  K3S PRODUCTION CLUSTER - FULL STACK CREDENTIALS & ACCESS CHEAT-SHEET
# ==============================================================================

## 🖥️ 1. HẠ TẦNG MÁY CHỦ (OS & SSH)
- User: cpdt
- Password: cpdt@123
- SSH Port: 22
- Master Nodes:
  * node-0: 10.3.232.20
  * node-1: 10.3.232.21
  * node-2: 10.3.232.22
- Worker Nodes:
  * node-3: 10.3.232.30
  * node-4: 10.3.232.31
  * node-6: 10.3.232.33
  * node-7: 10.3.232.34
  * node-8: 10.3.232.35
  * node-9: 10.3.232.36
  * node-10: 10.3.232.37

------------------------------------------------------------------------------

## 🎛️ 2. OPENSHIFT WEB CONSOLE & DEX SSO
- Local URL:   http://localhost:30900
- Direct URL:  http://10.3.232.20:30900
- LB VIP:      http://10.200.10.3
- Dex SSO URL: https://10.3.232.20:32000 (LB: https://10.200.10.2)
- Accounts:
  * SuperAdmin: superadmin@mbfs.vn  /  Admin@2026   (Cluster Admin)
  * Admin:      admin@mbfs.vn       /  Mbfs@2026    (Namespace Admin)
  * Developer:  dev@mbfs.vn         /  Mbfs@2026    (Read / Write)

------------------------------------------------------------------------------

## 🐙 3. ARGOCD GITOPS CI/CD
- Local URL:   https://localhost:30246
- Direct URL:  https://10.3.232.20:30246
- LB VIP:      https://10.200.10.8:443
- Username:    admin
- Password:    Admin@2026
- CLI Login:
  argocd login 10.200.10.8:443 --username admin --password 'Admin@2026' --insecure

------------------------------------------------------------------------------

## 📊 4. LOGGING STACK (ELASTICSEARCH, KIBANA, APM, VECTOR)
- Kibana Local:  http://localhost:30601
- Kibana Direct: http://10.3.232.20:30601
- Elasticsearch: https://elasticsearch-es-http.logging.svc:9200
- APM Server:    http://apm-apm-http.logging.svc:8200
- Username:      elastic
- Password:      4spdx7xxC13yYuaTWKhqXgwx
- Storage:       Longhorn 40Gi (Replicas: 2)
- Index Pattern: k8s-app-*

------------------------------------------------------------------------------

## 🏛️ 5. ORACLE DATABASE 21C XE
- Direct Port: 10.3.232.20:31521
- LB VIP:      10.200.10.4:1521
- SID:         XE
- PDB:         XEPDB1
- Users:       SYS / SYSTEM
- Password:    Oracle@2026
- Storage:     Longhorn 30Gi

------------------------------------------------------------------------------

## ⚡ 6. REDIS CLUSTER HA (3 MASTERS)
- Direct Port: 10.3.232.20:31379
- LB VIP:      10.200.10.5:6379
- Password:    Redis@2026
- Hash Slots:  16,384 (100% active)
- Storage:     3 x Longhorn 10Gi

------------------------------------------------------------------------------

## 📦 7. MINIO S3 OBJECT STORAGE
- Console Local:  http://localhost:31901
- Console Direct: http://10.3.232.20:31901 (LB: http://10.200.10.7:9001)
- S3 API Direct:  http://10.3.232.20:31900 (LB: http://10.200.10.7:9000)
- Access Key:     minioadmin
- Secret Key:     Minio@2026
- Default Buckets: backups, uploads
- Storage:        Longhorn 40Gi

------------------------------------------------------------------------------

## 🐼 8. REDPANDA (KAFKA PLATFORM & WEB CONSOLE)
- Console Local:  http://localhost:31080
- Console Direct: http://10.3.232.20:31080 (LB: http://10.200.10.6)
- Kafka Broker:   10.3.232.20:31092
- Schema Reg:     10.3.232.20:31081
- Auth:           No auth (Internal Cluster Mesh)
- Storage:        Longhorn 20Gi

------------------------------------------------------------------------------

## 💾 9. LONGHORN DISTRIBUTED STORAGE UI
- UI Local:   http://localhost:30800
- UI Direct:  http://10.3.232.20:30800
- LB VIP:     http://10.200.10.1
- Auth:       Disabled (Internal UI)
- Thin Provisioning: 500% Oversubscription enabled

------------------------------------------------------------------------------

## 🔌 10. LỆNH MỞ SSH TUNNEL TRÊN MÁY MAC (KHI CẦN KẾT NỐI LẠI)
ssh -f -N \
  -L 30900:10.3.232.20:30900 \
  -L 32000:10.3.232.20:32000 \
  -L 30246:10.3.232.20:30246 \
  -L 30601:10.3.232.20:30601 \
  -L 31080:10.3.232.20:31080 \
  -L 31901:10.3.232.20:31901 \
  -L 30800:10.3.232.20:30800 \
  -L 6443:10.3.232.20:6443 \
  -D 1080 \
  cpdt@10.3.232.20
# ==============================================================================
