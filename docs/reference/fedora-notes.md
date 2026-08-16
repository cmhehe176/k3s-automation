# ⚠️ Fedora Workstation cho K3s Nodes - Lưu Ý

**Date**: 2026-08-16  
**Question**: Có thể dùng Fedora Workstation cho Node-1 không?

---

## Câu Trả Lời Ngắn

**✅ CÓ THỂ** - K3s hỗ trợ Fedora  
**⚠️ KHÔNG KHUYẾN NGHỊ** - Cho production  
**💡 TỐT HƠN** - Dùng Ubuntu Server 22.04 LTS hoặc Fedora Server

---

## Chi Tiết

### Fedora Workstation CÓ THỂ chạy K3s vì:

✅ Kernel 5.4+ (Fedora 44 có kernel 6.x)  
✅ systemd  
✅ cgroups v2 support  
✅ Container runtime compatible  
✅ K3s official support cho Fedora

### NHƯNG Không Tối Ưu Vì:

❌ **Desktop Overhead**: GNOME + desktop packages tốn **2-4GB RAM**
- Node 32GB → chỉ còn ~28GB cho K3s (thay vì 30GB)
- CPU cycles cho desktop services

❌ **Short Lifecycle**: Fedora EOL sau **6 tháng**
- Ubuntu LTS: 5 năm support
- Fedora 44 → EOL ~Feb 2027

❌ **SELinux Policies**: Desktop SELinux phức tạp hơn server
- Có thể gây issues với container volumes
- Cần troubleshoot nhiều hơn

❌ **Update Frequency**: Fedora update rất thường xuyên
- Risk kernel updates break K3s
- Cần test kỹ mỗi update

❌ **Không Optimize**: Cho server workloads
- Kernel tuning cho desktop
- Scheduler settings cho desktop
- Power management cho laptop/desktop

---

## So Sánh

| Aspect | Ubuntu Server 22.04 | Fedora Server 36+ | Fedora Workstation 44 |
|--------|---------------------|-------------------|----------------------|
| RAM overhead | ~1GB | ~1GB | ~3-4GB |
| Support lifecycle | 5 years | 13 months | 6 months |
| K3s compatibility | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Production ready | ✅ Yes | ✅ Yes | ⚠️ Not recommended |
| Ease of setup | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## Khuyến Nghị

### Scenario 1: Test/Lab (OK dùng Fedora Workstation)

Nếu bạn chỉ test K3s, học tập, hoặc POC:
- ✅ **Dùng Fedora Workstation được**
- Tiết kiệm không cần cài OS mới
- Đủ để verify cluster hoạt động
- Không phải production data

### Scenario 2: Production (KHÔNG dùng Fedora Workstation)

Nếu đây là production cluster:
- ❌ **Không dùng Fedora Workstation**
- ✅ Cài **Ubuntu 22.04 LTS Server**
- Hoặc ✅ **Fedora Server** (nếu muốn Fedora ecosystem)
- Stability + long-term support quan trọng hơn

---

## Nếu Bạn Vẫn Muốn Dùng Fedora Workstation

### Bước 1: Disable Desktop Services (Optional)

```bash
# Disable GNOME auto-start on boot
sudo systemctl set-default multi-user.target

# Reboot
sudo reboot

# Máy sẽ boot vào text mode (no GUI)
# Login qua SSH hoặc tty
```

### Bước 2: Giảm RAM Usage

```bash
# Stop desktop services
sudo systemctl stop gdm
sudo systemctl disable gdm

# Check RAM saved
free -h
# Expected: ~2-3GB freed
```

### Bước 3: Cài K3s Bình Thường

```bash
# Follow DEPLOY.md như thường
cd ~/pro/cicd-ndc/k3s-automation/ansible/
./bootstrap.sh
```

### Bước 4: Monitor Resources

```bash
# Watch RAM usage
watch -n 2 free -h

# Watch CPU
htop
```

---

## Kết Luận

**Cho Node-1 Test/Learning:**
```bash
✅ Fedora Workstation 44 → OK
   Just run: ./bootstrap.sh
```

**Cho Production Cluster:**
```bash
❌ Fedora Workstation → Reinstall OS
✅ Ubuntu 22.04 LTS Server → Recommended
   Download: https://ubuntu.com/download/server
```

**Timeline:**
- Test trên Fedora Workstation: 0 phút setup (đã có)
- Reinstall Ubuntu Server: ~30 phút

**Decision Tree:**
```
Đây là production? 
├─ Yes → Cài Ubuntu 22.04 LTS Server
└─ No (test/lab) → Dùng Fedora Workstation luôn
```

---

## Commands để Check Compatibility

```bash
# Check kernel version (cần >= 5.4)
uname -r
# Fedora 44: 6.x.x → ✅ OK

# Check systemd
systemctl --version
# Expected: systemd 255+ → ✅ OK

# Check cgroups
mount | grep cgroup
# Expected: cgroup2 → ✅ OK

# Check swap (phải disabled)
swapon -s
# Expected: no output → ✅ OK

# Check available RAM
free -h
# Fedora Workstation: ~28GB available (32GB - 4GB desktop)
# Ubuntu Server: ~30GB available (32GB - 2GB system)
```

---

## FAQ

**Q: Fedora Workstation có chạy được K3s không?**  
A: Có, hoàn toàn chạy được.

**Q: Production có nên dùng không?**  
A: Không. Dùng Ubuntu Server hoặc Fedora Server.

**Q: Tôi đã có Fedora Workstation, phải cài lại không?**  
A: 
- Test/lab: Không cần, dùng luôn
- Production: Nên cài lại Ubuntu Server

**Q: Performance khác biệt nhiều không?**  
A: 
- RAM: -2-4GB (desktop overhead)
- CPU: -5-10% (desktop services)
- Disk I/O: Tương đương
→ Cho test OK, production nên optimize

**Q: Nếu tôi disable GNOME thì sao?**  
A: Tốt hơn, nhưng vẫn có desktop packages nền. Ubuntu Server cleaner.

---

**Created**: 2026-08-16  
**Status**: Informational  
**Recommendation**: Use Ubuntu 22.04 LTS Server for production
