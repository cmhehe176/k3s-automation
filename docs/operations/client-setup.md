# 💻 Hướng Dẫn Cài Đặt & Cấu Hình Máy Client (Ansible Controller)

Tài liệu này hướng dẫn chuẩn bị môi trường trên **máy Client / Bastion / Laptop quản trị** để chạy bộ tự động hóa `./cluster.sh` và các Ansible Playbook của dự án **K3s Cluster Automation**.

---

## 🎯 1. Yêu cầu trên Máy Client

Máy Client (máy bạn đang dùng để gõ `./cluster.sh`) cần có các công cụ sau:

- **Python 3.9+** & `pip`
- **Ansible Core (hoặc Ansible 2.14+)** (cung cấp lệnh `ansible`, `ansible-playbook`)
- **OpenSSH Client** & **sshpass** (để truyền SSH password tự động nếu chưa cấu hình SSH Key)
- **kubectl** (để tương tác trực tiếp với cụm K3s sau khi triển khai)
- **Git** (để quản lý mã nguồn)

---

## 🍎 2. Cài Đặt Trên macOS (Khuyên dùng Homebrew)

Nếu bạn đang sử dụng **macOS** (như máy hiện tại), cách nhanh và chuẩn nhất là dùng **Homebrew**:

```bash
# 1. Cập nhật Homebrew
brew update

# 2. Cài đặt Ansible, sshpass, kubectl
brew install ansible sshpass kubectl

# 3. (Tùy chọn) Cài thêm helm nếu cần quản lý Helm chart
brew install helm
```

> **Lưu ý với `sshpass` trên macOS:**  
> Nếu `brew install sshpass` báo lỗi không có sẵn trong core tap, bạn có thể cài qua tap thay thế:
> ```bash
> brew install hudochenkov/sshpass/sshpass
> ```

---

## 🐧 3. Cài Đặt Trên Linux (Ubuntu / Debian / RHEL / Fedora)

### A. Ubuntu / Debian
```bash
sudo apt update
sudo apt install -y python3 python3-pip python3-venv sshpass git curl

# Cài đặt Ansible chính thức qua PPA
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Cài đặt kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### B. RHEL / Rocky Linux / AlmaLinux / CentOS Stream
```bash
sudo dnf install -y epel-release
sudo dnf install -y ansible sshpass git python3-pip curl
```

### C. Fedora
```bash
sudo dnf install -y ansible sshpass git kubectl python3-pip
```

---

## 🪟 4. Cài Đặt Trên Windows

Khuyến nghị sử dụng **WSL2 (Windows Subsystem for Linux)** chạy **Ubuntu 22.04 / 24.04**, sau đó làm theo hướng dẫn phần **Linux (Ubuntu/Debian)** ở trên.

---

## 🐍 5. Cài Đặt Qua Python Pip (Mọi hệ điều hành)

Nếu bạn muốn quản lý Ansible thông qua môi trường ảo Python (`venv`):

```bash
# 1. Tạo và kích hoạt môi trường ảo (Virtual Environment)
python3 -m venv ~/.ansible-venv
source ~/.ansible-venv/bin/activate

# 2. Cài đặt Ansible và các thư viện Python bổ trợ
pip install --upgrade pip
pip install ansible pyyaml kubernetes
```

*(Mỗi lần mở terminal mới để chạy script, hãy gõ `source ~/.ansible-venv/bin/activate`)*

---

## 📦 6. Cài Đặt Các Ansible Collections Bổ Trợ

Để các playbook vận hành trơn tru với các module hệ thống và Kubernetes, chạy lệnh sau trên máy client:

```bash
ansible-galaxy collection install ansible.posix community.general kubernetes.core
```

---

## 🔑 7. Cấu Hình SSH Key Tới Các Target Nodes

Để Ansible kết nối đến các Node máy chủ mượt mà mà không cần nhập mật khẩu liên tục:

### Bước 1: Tạo SSH Key (nếu máy client chưa có)
```bash
ssh-keygen -t ed25519 -C "k3s-automation" -f ~/.ssh/id_rsa -N ""
```

### Bước 2: Copy SSH Key sang các Node trong cụm
Thay thế `user` và `node-ip` tương ứng trong file `ansible/inventory/hosts.ini`:

```bash
# Ví dụ cho Node-1, Node-2, Node-3
ssh-copy-id root@192.168.1.10
ssh-copy-id root@192.168.1.11
ssh-copy-id root@192.168.1.12
```

---

## ✅ 8. Kiểm Tra & Chạy Lại Cluster Script

### Kiểm tra kết nối Ansible tới các Node:
```bash
cd /Users/congminh/pro/k3s-automation
ansible k3s_cluster -m ping -i ansible/inventory/hosts.ini
```

### Chạy lại trình điều khiển Cluster Automation:
```bash
./cluster.sh
```
hoặc chạy trực tiếp các lệnh CLI:
```bash
./cluster.sh bootstrap           # Bootstrap K3s Core, MetalLB, Longhorn
./cluster.sh middleware deploy   # Deploy Oracle, Redis, Redpanda, MinIO
./cluster.sh console deploy      # Deploy OpenShift Console
```
