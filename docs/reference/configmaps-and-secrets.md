# 📦 ConfigMap & Secret Decoupling Reference

Tài liệu này ghi lại kiến trúc và chuẩn thiết kế **"Không Fix Cứng Cấu Hình (No Hardcoding - Dynamic ConfigMap/Secret Injection Pattern)"** được áp dụng cho toàn bộ các ứng dụng và middleware trong cụm K3s.

---

## 🎯 1. Nguyên Tắc Thiết Kế (Cloud-Native Best Practices)

1. **Tuyệt đối không hardcode trong Container Spec:**  
   Mọi tham số kết nối (`HOST`, `PORT`, `URL`, `BROKERS`, `BUCKETS`), cấu hình runtime và thông tin đăng nhập đều **không được gán cứng chuỗi (string literal)** trực tiếp vào block `env:` hay command của Pod.

2. **Tách biệt tầng Cấu hình (Config) và Mã nguồn/Manifest:**  
   - Thông tin kết nối & cấu hình runtime $\rightarrow$ Đẩy vào **`ConfigMap`**.
   - Mật khẩu, private keys, certificates, cookie keys $\rightarrow$ Đẩy vào **`Secret`**.

3. **Truy xuất động tại thời điểm chạy (Runtime Injection):**  
   Container trong Pod nạp cấu hình thông qua 3 cơ chế chuẩn của Kubernetes:
   - `valueFrom.configMapKeyRef`: Đọc từng biến cụ thể từ ConfigMap.
   - `envFrom.configMapRef`: Nạp toàn bộ key-value trong ConfigMap thành biến môi trường.
   - `volumeMount` (ConfigMap / Secret): Gắn trực tiếp file cấu hình (ví dụ: `redis.conf`, `config.yaml`, certificates) vào container.

---

## 📋 2. Bảng Tổng Hợp ConfigMaps & Secrets của Toàn Bộ Ứng Dụng

### 🗄️ Oracle Database XE (`oracle`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **ConfigMap** | `oracle-info` | `oracle` | `HOST`, `PORT`, `SERVICE_NAME`, `SID`, `SYS_PASSWORD`, `APP_USER`, `APP_PASSWORD` | `configMapKeyRef` ➔ `ORACLE_PASSWORD`, `APP_USER`, `APP_USER_PASSWORD` |
| **Secret** | `oracle-secret` | `oracle` | `ORACLE_PASSWORD`, `APP_USER`, `APP_USER_PASSWORD` | K8s Opaque Secret |

---

### ⚡ Redis Cluster (`redis`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **ConfigMap** | `redis-info` | `redis` | `HOST`, `PORT`, `PASSWORD` | `configMapKeyRef` ➔ `REDIS_PASSWORD` |
| **ConfigMap** | `redis-cluster-config` | `redis` | `redis.conf`: File cấu hình cluster động (port, timeouts, appendonly, requirepass) | `volumeMount` tại `/etc/redis` |
| **Secret** | `redis-secret` | `redis` | `REDIS_PASSWORD` | K8s Opaque Secret |

---

### 🐼 Redpanda / Kafka Cluster (`redpanda`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **ConfigMap** | `redpanda-info` | `redpanda` | `KAFKA_BOOTSTRAP_SERVER`<br>`INTERNAL_BOOTSTRAP_SERVER`<br>`SCHEMA_REGISTRY_URL`<br>`INTERNAL_SCHEMA_REGISTRY`<br>`CONSOLE_URL` | • **Redpanda Pod:** `configMapKeyRef`<br>• **Web Console Pod:** `configMapKeyRef` (`KAFKA_BROKERS`, `KAFKA_SCHEMAREGISTRY_URLS`) |

---

### 🪣 MinIO S3 Object Storage (`minio`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **ConfigMap** | `minio-info` | `minio` | `HOST`, `S3_API_PORT`, `CONSOLE_PORT`, `ROOT_USER`, `ROOT_PASSWORD`, `DEFAULT_BUCKETS` | `configMapKeyRef` ➔ `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` |
| **Secret** | `minio-secret` | `minio` | `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` | K8s Opaque Secret |

---

### 🔴 Red Hat OpenShift Console & Dex OIDC (`openshift-console`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **ConfigMap** | `console-config` | `openshift-console` | `BRIDGE_USER_AUTH_OIDC_ISSUER_URL`<br>`BRIDGE_USER_AUTH_OIDC_CLIENT_ID`<br>`BRIDGE_USER_AUTH_OIDC_CA_FILE`<br>`BRIDGE_BASE_ADDRESS`<br>`BRIDGE_CUSTOM_PRODUCT_NAME` | `envFrom.configMapRef` (Tự động nạp toàn bộ cấu hình) |
| **ConfigMap** | `console-custom-logos` | `openshift-console` | Logo Light/Dark theme cho giao diện | `volumeMount` tại `/var/run/secrets/console-logos` |
| **ConfigMap** | `dex-config` | `openshift-console` | File cấu hình `config.yaml` của Dex SSO | `volumeMount` tại `/etc/dex/cfg` |
| **Secret** | `console-cookie-keys` | `openshift-console` | `cookie-encryption-key`, `cookie-authentication-key` | `volumeMount` tại `/var/run/secrets/console-cookie-keys` |
| **Secret** | `dex-tls` | `openshift-console` | `tls.crt`, `tls.key`, `ca.crt` (OIDC HTTPS/TLS) | `volumeMount` tại `/var/run/secrets/dex-tls` |

---

### 🐙 ArgoCD GitOps (`argocd`)

| Đối tượng K8s | Tên | Namespace | Các Keys & Mục đích | Cách Container nạp |
|---|---|---|---|---|
| **Secret** | `argocd-initial-admin-secret` | `argocd` | Mật khẩu quản trị ban đầu của Web UI | Upstream Dynamic Secret |
| **Service** | `argocd-server` | `argocd` | Cấp phát IP Ingress tự động qua MetalLB LoadBalancer | `spec.type: LoadBalancer` |

---

## 🔍 3. Hướng Dẫn Kiểm Tra và Đọc Cấu Hình Từ Terminal

Sau khi cụm được triển khai, các ứng dụng microservices hoặc admin có thể tra cứu thông tin kết nối bằng lệnh `kubectl`:

```bash
# Đọc thông tin kết nối Oracle DB:
kubectl get configmap oracle-info -n oracle -o yaml

# Đọc thông tin kết nối Redis Cluster:
kubectl get configmap redis-info -n redis -o yaml

# Đọc Endpoint Kafka & Schema Registry:
kubectl get configmap redpanda-info -n redpanda -o yaml

# Đọc thông tin MinIO S3:
kubectl get configmap minio-info -n minio -o yaml

# Đọc cấu hình OpenShift Console:
kubectl get configmap console-config -n openshift-console -o yaml
```
