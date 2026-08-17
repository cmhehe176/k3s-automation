# K3s Middleware & Database Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Triển khai bộ phần mềm hạ tầng Middleware & Database doanh nghiệp hoàn chỉnh trên K3s gồm **Oracle Database XE (19c/21c compatible)**, **Redis Cluster**, **Redpanda Cluster (Kafka Streaming)** và **MinIO S3 Object Storage**, tích hợp toàn diện với ổ cứng phân tán **Longhorn**, phân quyền **RBAC** và công cụ quản trị tự động **`cluster.sh`**.

**Architecture:** 
- Mỗi dịch vụ được tổ chức thành một module Ansible độc lập có cấu trúc chuẩn (`playbooks/deploy.yml`, `playbooks/uninstall.yml`, `templates/`, `vars/`).
- **Oracle Database XE:** Triển khai bản Oracle Express Edition tối ưu (`gvenzl/oracle-xe:21-slim` / 18c / 19c compatible) gắn kết với ổ cứng **Longhorn StorageClass** 30GB (`/opt/oracle/oradata`).
- **Redis Cluster:** Triển khai cụm phân tán **Redis Cluster** đa node (StatefulSet) với cơ chế tự động phân chia Hash Slots (16384 slots), tự động Failover và lưu trữ AOF/RDB bền vững trên Longhorn.
- **Redpanda Cluster:** Triển khai cụm **Redpanda Cluster** (Raft consensus đa node, C++ native Kafka API không cần Zookeeper) + **Redpanda Web Console Dashboard**.
- **MinIO S3:** Triển khai **MinIO Object Storage** + **MinIO Web Console** gắn ổ cứng Longhorn 40GB.
- Mở cổng kết nối qua **NodePort** cố định trong dải `30000-32767`, sẵn sàng tích hợp với Ingress/Domain.
- Tích hợp Menu và lệnh CLI vào `./cluster.sh` để quản trị 1-click.

**Tech Stack:**
- **Oracle Database XE** (`gvenzl/oracle-xe:21-slim`, SID `XEPDB1`/`XE`, port 1521, NodePort 31521)
- **Redis Cluster** (`redis:7.2-alpine`, cluster bus port 16379, client port 6379, NodePort 36379)
- **Redpanda Cluster (Kafka API)** (`docker.redpanda.com/redpandadata/redpanda:latest` + Console, ports 9092/8081/8080, NodePorts 39092/38081/38080)
- **MinIO S3 Object Storage** (`minio/minio:latest`, S3 API port 9000, Web Console port 9001, NodePorts 39000/39001)
- **Ansible Automation & Bash CLI** (`cluster.sh`)

---

## 📋 Danh sách cổng & Thông tin dịch vụ dự kiến

| Dịch vụ | Namespace | Cổng nội bộ | NodePort mở ngoài | Web UI / Giao diện | Mục đích sử dụng |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Oracle Database XE** | `database` | `1521` | `31521` | Quản lý qua OpenShift Console / DBeaver | Database RDBMS chính (SID `XEPDB1`) |
| **Redis Cluster** | `middleware` | `6379`, `16379` | `36379` | Quản lý qua OpenShift Console / RedisInsight | Distributed Cache & In-Memory KV Store |
| **Redpanda Cluster** | `middleware` | `9092` (Kafka), `8081` (Schema) | `39092`, `38081` | Quản lý qua Redpanda Web Console | Message Queue & Event Streaming Cluster |
| **Redpanda Web Console** | `middleware` | `8080` | `38080` | `http://ndmc.pro:38080` | Dashboard trực quan xem Topics, Messages |
| **MinIO S3 API** | `storage` | `9000` | `39000` | Kết nối qua AWS S3 SDK / S3cmd | Lưu trữ Object Storage (ảnh, video, backup) |
| **MinIO Web Console** | `storage` | `9001` | `39001` | `http://ndmc.pro:39001` | Dashboard quản lý Buckets, Files, Users |

---

## 🛠️ Kế hoạch triển khai chi tiết từng Task (Bite-sized Tasks)

### Task 1: Module Oracle Database XE

**Files:**
- Create: `ansible/oracle/vars/main.yml`
- Create: `ansible/oracle/templates/oracle.yaml.j2`
- Create: `ansible/oracle/playbooks/deploy.yml`
- Create: `ansible/oracle/playbooks/uninstall.yml`
- Create: `ansible/oracle/README.md`

- [ ] **Step 1.1: Tạo file cấu hình biến `oracle/vars/main.yml`**
  - Khai báo image `gvenzl/oracle-xe:21-slim`, mật khẩu SYS/SYSTEM, tên app_user, app_password, dung lượng đĩa Longhorn (30Gi), NodePort 31521.
- [ ] **Step 1.2: Tạo template Kubernetes manifest `oracle/templates/oracle.yaml.j2`**
  - Namespace `database`, Secret lưu mật khẩu, PVC `storageClassName: longhorn`, Deployment với health checks (Liveness/Readiness), Service NodePort 31521.
- [ ] **Step 1.3: Viết Ansible Playbook `oracle/playbooks/deploy.yml` & `uninstall.yml`**
  - Triển khai manifest, chờ Pod sẵn sàng (`kubectl wait`), in thông tin kết nối SID `XEPDB1` / `XE`.
- [ ] **Step 1.4: Kiểm thử triển khai và kiểm tra kết nối SQL `SELECT 1 FROM DUAL`**
  - Chạy lệnh test kết nối trực tiếp vào Oracle container.

---

### Task 2: Module Redis Cluster (Distributed StatefulSet)

**Files:**
- Create: `ansible/redis/vars/main.yml`
- Create: `ansible/redis/templates/redis-cluster.yaml.j2`
- Create: `ansible/redis/playbooks/deploy.yml`
- Create: `ansible/redis/playbooks/uninstall.yml`
- Create: `ansible/redis/README.md`

- [ ] **Step 2.1: Tạo file cấu hình biến `redis/vars/main.yml`**
  - Mật khẩu Redis Cluster, số lượng replicas/nodes (3 hoặc 6), cổng NodePort 36379, dung lượng đĩa Longhorn (10Gi mỗi node).
- [ ] **Step 2.2: Tạo template Kubernetes manifest `redis/templates/redis-cluster.yaml.j2`**
  - Namespace `middleware`, ConfigMap cấu hình `cluster-enabled yes`, `appendonly yes` và `requirepass`, Secret, StatefulSet với `volumeClaimTemplates` gắn Longhorn, Service Headless và Service NodePort 36379, Job khởi tạo cluster slots (`redis-cli --cluster create`).
- [ ] **Step 2.3: Viết Ansible Playbook `redis/playbooks/deploy.yml` & `uninstall.yml`**
  - Tự động tạo namespace, apply manifest, đợi các node Redis sẵn sàng và khởi tạo Cluster Hash Slots.
- [ ] **Step 2.4: Kiểm thử ghi/đọc key trên Cluster với mật khẩu `redis-cli -c -a <password> cluster info`**
  - Chạy test tự động xác nhận `cluster_state:ok` và `SET/GET test_key` với cơ chế hash slot redirect.

---

### Task 3: Module Redpanda Cluster (Kafka Native Raft + Web Console)

**Files:**
- Create: `ansible/redpanda/vars/main.yml`
- Create: `ansible/redpanda/templates/redpanda-cluster.yaml.j2`
- Create: `ansible/redpanda/playbooks/deploy.yml`
- Create: `ansible/redpanda/playbooks/uninstall.yml`
- Create: `ansible/redpanda/README.md`

- [ ] **Step 3.1: Tạo file cấu hình biến `redpanda/vars/main.yml`**
  - Cổng Kafka API (39092), Schema Registry (38081), Redpanda Console (38080), số broker (3 nodes hoặc 1 node cluster), dung lượng đĩa Longhorn (20Gi).
- [ ] **Step 3.2: Tạo template Kubernetes manifest `redpanda/templates/redpanda-cluster.yaml.j2`**
  - Namespace `middleware`, StatefulSet Redpanda Cluster (Raft consensus phân tán, không cần Zookeeper), Deployment Redpanda Web Console, Services NodePort.
- [ ] **Step 3.3: Viết Ansible Playbook `redpanda/playbooks/deploy.yml` & `uninstall.yml`**
  - Triển khai Redpanda Cluster + Web Console, kiểm tra readiness của cluster.
- [ ] **Step 3.4: Kiểm thử tạo Topic và Produce/Consume message**
  - Dùng lệnh `rpk cluster info`, tạo topic `demo-topic`, produce/consume 1 tin nhắn test.

---

### Task 4: Module MinIO S3 Object Storage + Web Console

**Files:**
- Create: `ansible/minio/vars/main.yml`
- Create: `ansible/minio/templates/minio.yaml.j2`
- Create: `ansible/minio/playbooks/deploy.yml`
- Create: `ansible/minio/playbooks/uninstall.yml`
- Create: `ansible/minio/README.md`

- [ ] **Step 4.1: Tạo file cấu hình biến `minio/vars/main.yml`**
  - Root User, Root Password, Cổng S3 API (39000), Cổng Web Console (39001), dung lượng đĩa Longhorn (40Gi), danh sách default buckets (`backups`, `uploads`).
- [ ] **Step 4.2: Tạo template Kubernetes manifest `minio/templates/minio.yaml.j2`**
  - Namespace `storage`, Secret mật khẩu, PVC Longhorn 40Gi, Deployment MinIO với Server & Console command, Job tự động tạo default buckets qua `mc` (MinIO Client), Service NodePort 39000/39001.
- [ ] **Step 4.3: Viết Ansible Playbook `minio/playbooks/deploy.yml` & `uninstall.yml`**
  - Triển khai MinIO, đợi Web Console sẵn sàng.
- [ ] **Step 4.4: Kiểm thử S3 API upload/download file qua MinIO Client**
  - Test kết nối và upload 1 file test vào bucket `uploads`.

---

### Task 5: Tích hợp Unified CLI & Interactive Menu (`cluster.sh`)

**Files:**
- Modify: `ansible/cluster.sh`
- Modify: `cluster.sh` (root wrapper)
- Modify: `README.md` & `COMPLETE_GUIDE.md`

- [ ] **Step 5.1: Bổ sung lệnh CLI quản trị Middleware vào `cluster.sh`**
  - Hỗ trợ cú pháp:
    - `./cluster.sh middleware deploy [oracle|redis|redpanda|minio|all]`
    - `./cluster.sh middleware uninstall [oracle|redis|redpanda|minio|all]`
- [ ] **Step 5.2: Bổ sung Menu tương tác số `10) Quản lý Middleware Stack` trong `cluster.sh`**
  - Menu con cho phép chọn cài đặt/gỡ từng dịch vụ hoặc toàn bộ trong 1 bấm.
- [ ] **Step 5.3: Cập nhật tài liệu tổng hợp và kiểm tra cú pháp toàn bộ dự án**
  - Chạy `ansible-playbook --syntax-check` trên toàn bộ playbooks mới.
