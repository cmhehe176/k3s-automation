#!/usr/bin/env bash
set -euo pipefail

ANSIBLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ANSIBLE_DIR"

REPORT_FILE="${REPORT_FILE:-$ANSIBLE_DIR/stress_test_10x.log}"
echo "==========================================================" | tee "$REPORT_FILE"
echo "🚀 KIỂM THỬ TUẦN TỰ 10 VÒNG (DEPLOY -> VERIFY -> TEARDOWN)" | tee -a "$REPORT_FILE"
echo "Thời gian bắt đầu: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
echo "==========================================================" | tee -a "$REPORT_FILE"

TOTAL_ROUNDS=10
PASSED_ROUNDS=0
FAILED_ROUNDS=0

for i in $(seq 1 $TOTAL_ROUNDS); do
  echo "" | tee -a "$REPORT_FILE"
  echo "==========================================================" | tee -a "$REPORT_FILE"
  echo "🔄 BẮT ĐẦU VÒNG $i / $TOTAL_ROUNDS ($(date '+%H:%M:%S'))" | tee -a "$REPORT_FILE"
  echo "==========================================================" | tee -a "$REPORT_FILE"

  # 1. DEPLOY TUẦN TỰ TOÀN BỘ 10 PLAYBOOKS
  echo "▶️ [VÒNG $i] Đang triển khai toàn bộ 10 playbooks..." | tee -a "$REPORT_FILE"
  if ansible-playbook -i inventory/hosts.ini \
      k3s/playbooks/00-prerequisites.yml \
      k3s/playbooks/01-k3s-control.yml \
      k3s/playbooks/03-metallb.yml \
      k3s/playbooks/04-longhorn.yml \
      openshift-console/playbooks/deploy.yml \
      oracle/playbooks/deploy.yml \
      redis/playbooks/deploy.yml \
      redpanda/playbooks/deploy.yml \
      minio/playbooks/deploy.yml \
      argocd/playbooks/deploy.yml >> "$REPORT_FILE" 2>&1; then
    echo "  ✅ Deploy 10 playbooks: THÀNH CÔNG!" | tee -a "$REPORT_FILE"
  else
    echo "  ❌ Deploy: THẤT BẠI!" | tee -a "$REPORT_FILE"
    FAILED_ROUNDS=$((FAILED_ROUNDS + 1))
    continue
  fi

  # 2. XÁC THỰC CLUSTER & PODS
  echo "🔍 [VÒNG $i] Kiểm tra trạng thái Cluster..." | tee -a "$REPORT_FILE"
  if ansible ${DEFAULT_CONTROL_NODE:-node-1} -i inventory/hosts.ini -m ping >> "$REPORT_FILE" 2>&1; then
    echo "  ✅ SSH Connectivity: OK" | tee -a "$REPORT_FILE"
  else
    echo "  ❌ SSH Connectivity: FAILED!" | tee -a "$REPORT_FILE"
    FAILED_ROUNDS=$((FAILED_ROUNDS + 1))
    break
  fi

  local_pods=$(ansible ${DEFAULT_CONTROL_NODE:-node-1} -i inventory/hosts.ini -m command -a "kubectl get pods -A --no-headers" 2>/dev/null | grep -E 'Running|Completed' | wc -l || true)
  echo "  ✅ Tổng số Pods hoạt động tốt: $local_pods pods" | tee -a "$REPORT_FILE"

  # 3. TEARDOWN SẠCH SẼ (Gỡ bỏ toàn bộ để khôi phục máy trắng)
  echo "🧹 [VÒNG $i] Chạy Teardown sạch sẽ..." | tee -a "$REPORT_FILE"
  if ansible-playbook -i inventory/hosts.ini k3s/playbooks/99-teardown.yml >> "$REPORT_FILE" 2>&1; then
    echo "  ✅ Teardown: THÀNH CÔNG!" | tee -a "$REPORT_FILE"
  else
    echo "  ❌ Teardown: THẤT BẠI!" | tee -a "$REPORT_FILE"
    FAILED_ROUNDS=$((FAILED_ROUNDS + 1))
    break
  fi

  # Kiểm tra SSH sau Teardown
  if ansible ${DEFAULT_CONTROL_NODE:-node-1} -i inventory/hosts.ini -m ping >> "$REPORT_FILE" 2>&1; then
    echo "  ✅ SSH sau Teardown: OK (Kết nối bình thường)" | tee -a "$REPORT_FILE"
  else
    echo "  ❌ SSH sau Teardown: MẤT KẾT NỐI!" | tee -a "$REPORT_FILE"
    FAILED_ROUNDS=$((FAILED_ROUNDS + 1))
    break
  fi

  PASSED_ROUNDS=$((PASSED_ROUNDS + 1))
  echo "🎉 [VÒNG $i / $TOTAL_ROUNDS] HOÀN THÀNH XUẤT SẮC!" | tee -a "$REPORT_FILE"
done

echo "" | tee -a "$REPORT_FILE"
echo "==========================================================" | tee -a "$REPORT_FILE"
echo "📊 TỔNG KẾT KIỂM THỬ 10 VÒNG:" | tee -a "$REPORT_FILE"
echo "  - Tổng số vòng: $TOTAL_ROUNDS" | tee -a "$REPORT_FILE"
echo "  - Thành công:   $PASSED_ROUNDS / $TOTAL_ROUNDS" | tee -a "$REPORT_FILE"
echo "  - Thất bại:     $FAILED_ROUNDS" | tee -a "$REPORT_FILE"
echo "Thời gian kết thúc: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$REPORT_FILE"
echo "==========================================================" | tee -a "$REPORT_FILE"
