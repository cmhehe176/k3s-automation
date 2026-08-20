# 🪵 Production Logging Stack (ECK, Elasticsearch, Kibana, APM, Vector) on K3s

Module tự động hóa triển khai cụm **Logging & Tracing tập trung** hoàn chỉnh trên K3s, bao gồm Elastic Cloud on Kubernetes (ECK Operator), Elasticsearch 9.5.0 cluster phân tán, Kibana Web Dashboard, Elastic APM Server, và Vector DaemonSet thu thập & xử lý log hiệu năng cao.

---

## 📌 1. Kiến Trúc & Thành Phần Hệ Thống

| Thành Phần | Phiên Bản | Loại Triển Khai | Cổng Kết Nối | Ghi Chú |
|---|---|---|---|---|
| **ECK Operator** | `3.5.0` | StatefulSet (1 Replica) | In-cluster | Quản trị vòng đời Elasticsearch, Kibana, APM |
| **Elasticsearch** | `9.5.0` | NodeSet (1 Node mặc định) | ClusterIP `9200` | Lưu trữ trên StorageClass `longhorn-es` (40GB/node) |
| **Kibana** | `9.5.0` | Deployment (1 Replica) | NodePort `30601` (Cổng nội bộ `5601`) | Web Dashboard phân tích log |
| **Elastic APM** | `9.5.0` | Deployment (1 Replica) | ClusterIP `8200` | Thu thập Application Performance Monitoring |
| **Vector** | `0.57.0` | DaemonSet (Mỗi node 1 pod) | In-cluster (`8686` API) | Thu thập container log, regex parser & VRL remap |

---

## 💾 2. Thiết Kế Lưu Trữ & Độ Sẵn Sàng (Storage Resilience)

* **StorageClass riêng biệt (`longhorn-es`):**
  * Do cluster gồm 2 worker/master nodes (`node-1`, `node-2`), cấu hình mặc định Longhorn `numberOfReplicas: 3` sẽ khiến Volume luôn ở trạng thái `Degraded`.
  * StorageClass `longhorn-es` được thiết lập tối ưu với `numberOfReplicas: 2`, `reclaimPolicy: Retain` giúp bảo vệ an toàn dữ liệu log khi pod khởi động lại.
* **Elasticsearch Node Scaling:**
  * Có thể mở rộng số node linh hoạt qua biến `elasticsearch_replicas` trong `ansible/logging/vars/main.yml`. Khi chạy nhiều node, cấu hình Soft Anti-Affinity (`preferredDuringSchedulingIgnoredDuringExecution`) sẽ tự động trải đều pods trên các node vật lý.

---

## ⚙️ 3. Pipeline Xử Lý Log Bằng Vector (VRL Engine)

DaemonSet **Vector** thu thập log từ `/var/log/pods/` với các bộ chuyển đổi VRL (Vector Remap Language):

1. **Multiline Aggregation:** Tự động gom các dòng log ngoại lệ / Stack Trace Java / Python bắt đầu bằng timestamp hoặc `[` thành 1 bản ghi duy nhất.
2. **Namespace Filtering:** Chỉ lọc và lập chỉ mục các log thuộc namespace ứng dụng được định nghĩa (`hn1-vdc-prod-core-backend-thanhtoantaptrung`, `hn1-vdc-prod-dmz-frontend-thanhtoantaptrung`).
3. **ANSI Color Stripping:** Làm sạch mã màu terminal ANSI.
4. **Trích xuất động Level & TraceID:** Regex tự động nhận diện Log Level (`INFO`, `WARN`, `ERROR`) và `traceId`/`requestId` (UUID hoặc chuỗi định danh).
5. **Index Đích:** Đẩy dữ liệu về Elasticsearch theo chỉ mục hàng ngày `k8s-app-YYYY.MM.DD`.

---

## 🚀 4. Lệnh Quản Trị 1-Click

```bash
# 1. Triển khai toàn bộ cụm Logging (Namespace: logging)
./cluster.sh logging deploy

# 2. Gỡ bỏ cụm Logging
./cluster.sh logging uninstall

# 3. Hoặc chọn mục 15 trong menu tương tác:
./cluster.sh
```

---

## 🔌 5. Truy Cập Web Console & Lấy Mật Khẩu

### Kibana Dashboard:
* **URL:** `http://<IP-Node>:30601` (VD: `http://192.168.1.237:30601`)
* **Username:** `elastic`
* **Lấy mật khẩu tài khoản `elastic`:**
  ```bash
  kubectl get secret elasticsearch-es-elastic-user -n logging -o jsonpath="{.data.elastic}" | base64 -d && echo ""
  ```

### Kiểm Tra Trạng Thái Sức Khỏe:
```bash
# Kiểm tra tài nguyên trong namespace logging
kubectl get all,pvc,sc -n logging

# Kiểm tra sức khỏe cluster Elasticsearch
kubectl get elasticsearch -n logging
```
