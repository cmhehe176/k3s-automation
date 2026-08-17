# 🐼 Redpanda (Kafka Streaming) on K3s with Longhorn Storage

Module tự động hóa triển khai **Redpanda Cluster** (hệ thống Message Queue / Event Streaming phân tán viết bằng C++, tương thích 100% Kafka API, không cần Zookeeper/JVM) kèm theo **Redpanda Web Console Dashboard** trên K3s.

---

## 📌 1. Thông tin kết nối mặc định

* **Namespace:** `redpanda`
* **Kafka Bootstrap Server:** `<node-ip-hoac-domain>:31092` (VD: `ndmc.pro:31092` hoặc `192.168.1.181:31092`)
* **Schema Registry URL:** `http://ndmc.pro:31081`
* **Redpanda Web Console:** `http://ndmc.pro:31080` *(Giao diện Web trực quan xem Topics, Messages, Consumers, Schemas)*
* **Dung lượng ổ cứng:** `20GB` (Gắn kết Longhorn PVC `/var/lib/redpanda/data`)

---

## 🚀 2. Lệnh quản trị 1-Click

```bash
# Triển khai Redpanda Cluster & Web Console (Namespace: redpanda)
./cluster.sh redpanda deploy

# Gỡ bỏ Redpanda Cluster
./cluster.sh redpanda uninstall
```

---

## 🔌 3. Quản trị qua dòng lệnh `rpk` (Redpanda CLI)

```bash
# Kiểm tra thông tin cụm Redpanda
kubectl exec -it redpanda-0 -n redpanda -- rpk cluster info

# Tạo Topic mới
kubectl exec -it redpanda-0 -n redpanda -- rpk topic create my-topic

# Bắn thử tin nhắn (Produce)
kubectl exec -it redpanda-0 -n redpanda -- rpk topic produce my-topic

# Đọc tin nhắn (Consume)
kubectl exec -it redpanda-0 -n redpanda -- rpk topic consume my-topic
```
