#!/usr/bin/env bash
# ==============================================================================
# 🚀 K3s Cluster Automation Master Wrapper
# ==============================================================================
set -e

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine project root (ansible/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/ansible/ansible.cfg" ]; then
    ROOT_DIR="${SCRIPT_DIR}/ansible"
elif [ -f "${SCRIPT_DIR}/ansible.cfg" ]; then
    ROOT_DIR="${SCRIPT_DIR}"
elif [ -f "${SCRIPT_DIR}/../ansible.cfg" ]; then
    ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
else
    echo -e "${RED}❌ Error: Could not locate ansible/ root directory containing ansible.cfg${NC}"
    exit 1
fi

cd "$ROOT_DIR"
export KUBECONFIG="${HOME}/.kube/config-k3s"

# Banner
print_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "================================================================"
    echo "          🚀 K3S CLUSTER AUTOMATION MANAGER"
    echo "================================================================"
    echo -e "${NC}"
}

# Help / Usage
show_help() {
    print_banner
    cat << EOF
Usage: ./cluster.sh <command> [arguments...]

Commands:
  deploy-all              Deploy Full Stack (Core K3s, MetalLB, Longhorn, Console, Oracle, Redis, Redpanda, MinIO, ArgoCD)
  bootstrap [node]        Deploy prerequisites and bootstrap K3s Control Plane
  teardown [options]      Teardown cluster (--all, --node <name>, --workers)
  add-node <node...>      Add worker node(s) to the cluster
  remove-node <node>      Remove a worker node cleanly from the cluster
  status                  Check SSH connectivity, node states, and cluster pods
  backup                  Create backup of K3s cluster state / etcd
  restore <file>          Restore cluster from a previous backup
  argocd <deploy|uninstall>
                          Manage ArgoCD GitOps deployment
  kubesphere <deploy|uninstall>
                          Manage KubeSphere console deployment
  console <deploy|uninstall>
                          Manage OpenShift Console Standalone deployment
  oracle <deploy|uninstall>
                          Manage Oracle Database 19c/23ai deployment
  redis <deploy|uninstall>
                          Manage Redis Cluster deployment
  redpanda <deploy|uninstall>
                          Manage Redpanda (Kafka) Cluster deployment
  minio <deploy|uninstall>
                          Manage MinIO S3 Object Storage deployment
  menu                    Open interactive management menu (default if no args)

Examples:
  ./cluster.sh deploy-all
  ./cluster.sh bootstrap node-1
  ./cluster.sh add-node node-2 node-3
  ./cluster.sh status
  ./cluster.sh console deploy
  ./cluster.sh oracle deploy
  ./cluster.sh redis deploy
  ./cluster.sh redpanda deploy
  ./cluster.sh minio deploy

EOF
}

# Command Handlers
cmd_deploy_all() {
    print_banner
    echo -e "${GREEN}${BOLD}🚀 BẮT ĐẦU QUY TRÌNH TRIỂN KHAI TOÀN DIỆN (FULL STACK DEPLOYMENT)${NC}"
    echo -e "${YELLOW}Thứ tự: Core (K3s, MetalLB, Longhorn) ➜ Console/Dex ➜ Middleware (Oracle, Redis, Redpanda, MinIO) ➜ ArgoCD ➜ Verification${NC}"
    echo "================================================================"
    echo ""

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 1/10] Chuẩn bị hạ tầng & gói OS (Prerequisites)...${NC}"
    ansible-playbook -i inventory/hosts.ini k3s/playbooks/00-prerequisites.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 2/10] Khởi tạo K3s Control Plane & CNI Network...${NC}"
    ansible-playbook -i inventory/hosts.ini k3s/playbooks/01-k3s-control.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 3/10] Cấu hình MetalLB LoadBalancer L2 & IP Pool...${NC}"
    ansible-playbook -i inventory/hosts.ini k3s/playbooks/03-metallb.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 4/10] Cài đặt Longhorn CSI Storage Driver & Default StorageClass...${NC}"
    ansible-playbook -i inventory/hosts.ini k3s/playbooks/04-longhorn.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 5/10] Triển khai Red Hat OpenShift Web Console & Dex OIDC SSO...${NC}"
    ansible-playbook -i inventory/hosts.ini openshift-console/playbooks/deploy.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 6/10] Triển khai Oracle Database XE với Persistent Storage...${NC}"
    ansible-playbook -i inventory/hosts.ini oracle/playbooks/deploy.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 7/10] Khởi tạo Redis Cluster (6 Pods, 16,384 Hash Slots)...${NC}"
    ansible-playbook -i inventory/hosts.ini redis/playbooks/deploy.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 8/10] Khởi tạo Redpanda Streaming Cluster & Web Console...${NC}"
    ansible-playbook -i inventory/hosts.ini redpanda/playbooks/deploy.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 9/10] Triển khai MinIO S3 Object Storage & Web Console...${NC}"
    ansible-playbook -i inventory/hosts.ini minio/playbooks/deploy.yml

    echo -e "${BOLD}${CYAN}▶️ [BƯỚC 10/10] Triển khai ArgoCD GitOps Continuous Delivery...${NC}"
    ansible-playbook -i inventory/hosts.ini argocd/playbooks/deploy.yml

    echo ""
    echo -e "${GREEN}${BOLD}🎉 TOÀN BỘ 10 BƯỚC TRIỂN KHAI ĐÃ HOÀN TẤT THÀNH CÔNG!${NC}"
    echo "================================================================"
    cmd_status
}

# Command Handlers
cmd_bootstrap() {
    local target_node="${1:-node-1}"
    print_banner
    echo -e "${YELLOW}🎯 Starting K3s Bootstrap on ${BOLD}${target_node}${NC}..."
    echo ""
    
    if [ -x "./k3s/scripts/bootstrap.sh" ]; then
        ./k3s/scripts/bootstrap.sh "$target_node"
    else
        echo -e "${BLUE}▶ Step 1/3: Preparing prerequisites...${NC}"
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/00-prerequisites.yml --limit "$target_node" --ask-become-pass
        echo -e "${BLUE}▶ Step 2/3: Installing K3s Control Plane...${NC}"
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/01-k3s-control.yml --limit "$target_node" --ask-become-pass
        echo -e "${BLUE}▶ Step 3/3: Deploying Core Addons (MetalLB & Longhorn)...${NC}"
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/03-metallb.yml --ask-become-pass || true
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/04-longhorn.yml --ask-become-pass || true
    fi
}

cmd_teardown() {
    print_banner
    echo -e "${RED}⚠️  Starting Cluster Teardown...${NC}"
    if [ -x "./k3s/scripts/teardown.sh" ]; then
        ./k3s/scripts/teardown.sh "$@"
    else
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/99-teardown.yml --ask-become-pass "$@"
    fi
}

cmd_add_node() {
    print_banner
    if [ $# -lt 1 ]; then
        echo -e "${RED}❌ Error: Please specify at least one worker node name (e.g., node-2)${NC}"
        exit 1
    fi
    echo -e "${YELLOW}➕ Adding worker node(s): ${BOLD}$*${NC}..."
    if [ -x "./k3s/scripts/add-node.sh" ]; then
        ./k3s/scripts/add-node.sh "$@"
    else
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/00-prerequisites.yml --limit "$1" --ask-become-pass
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/02-k3s-workers.yml --limit "$1" --ask-become-pass
    fi
}

cmd_remove_node() {
    print_banner
    if [ -z "${1:-}" ]; then
        echo -e "${RED}❌ Error: Please specify a node name to remove${NC}"
        exit 1
    fi
    echo -e "${YELLOW}➖ Removing worker node: ${BOLD}$1${NC}..."
    if [ -x "./k3s/scripts/remove-node.sh" ]; then
        ./k3s/scripts/remove-node.sh "$@"
    else
        ./cluster.sh teardown --node "$1"
    fi
}

cmd_status() {
    print_banner
    echo -e "${BOLD}${CYAN}📡 1. Testing Ansible SSH Connectivity:${NC}"
    ansible k3s_cluster -m ping -i inventory/hosts.ini || true
    echo ""

    echo -e "${BOLD}${CYAN}📊 2. Cluster Nodes (kubectl get nodes -o wide):${NC}"
    if kubectl --kubeconfig="$KUBECONFIG" get nodes -o wide 2>/dev/null; then
        echo ""
        echo -e "${BOLD}${CYAN}📦 3. Cluster Pods Overview:${NC}"
        kubectl --kubeconfig="$KUBECONFIG" get pods -A -o wide
    else
        echo -e "${YELLOW}⚠️  Could not connect to K3s API using ${KUBECONFIG}.${NC}"
        echo -e "   Run ${BOLD}./cluster.sh bootstrap${NC} if the cluster is not yet created."
    fi
    echo ""
}

cmd_backup() {
    print_banner
    echo -e "${YELLOW}💾 Creating Cluster Backup...${NC}"
    if [ -x "./k3s/scripts/backup.sh" ]; then
        ./k3s/scripts/backup.sh "$@"
    else
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/10-backup.yml --ask-become-pass
    fi
}

cmd_restore() {
    print_banner
    echo -e "${YELLOW}🔄 Restoring Cluster Backup...${NC}"
    if [ -x "./k3s/scripts/restore.sh" ]; then
        ./k3s/scripts/restore.sh "$@"
    else
        ansible-playbook -i inventory/hosts.ini k3s/playbooks/11-restore.yml --ask-become-pass "$@"
    fi
}

cmd_argocd() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🐙 Deploying ArgoCD...${NC}"
            if [ -x "./argocd/scripts/deploy-argocd.sh" ]; then
                ./argocd/scripts/deploy-argocd.sh
            else
                ansible-playbook -i inventory/hosts.ini argocd/playbooks/deploy.yml
            fi
            ;;
        uninstall|remove)
            echo -e "${RED}🐙 Uninstalling ArgoCD...${NC}"
            if [ -x "./argocd/scripts/uninstall-argocd.sh" ]; then
                ./argocd/scripts/uninstall-argocd.sh
            else
                ansible-playbook -i inventory/hosts.ini argocd/playbooks/uninstall.yml
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid ArgoCD action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_kubesphere() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🌐 Deploying KubeSphere...${NC}"
            if [ -x "./kubesphere/scripts/deploy-kubesphere.sh" ]; then
                ./kubesphere/scripts/deploy-kubesphere.sh
            else
                ansible-playbook -i inventory/hosts.ini kubesphere/playbooks/deploy.yml
            fi
            ;;
        uninstall|remove)
            echo -e "${RED}🌐 Uninstalling KubeSphere...${NC}"
            if [ -x "./kubesphere/scripts/uninstall-kubesphere.sh" ]; then
                ./kubesphere/scripts/uninstall-kubesphere.sh
            else
                ansible-playbook -i inventory/hosts.ini kubesphere/playbooks/uninstall.yml || true
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid KubeSphere action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_console() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🔴 Deploying OpenShift Console Standalone...${NC}"
            if [ -x "./openshift-console/scripts/deploy-console.sh" ]; then
                ./openshift-console/scripts/deploy-console.sh
            else
                ansible-playbook -i inventory/hosts.ini openshift-console/playbooks/deploy.yml
            fi
            ;;
        uninstall|remove)
            echo -e "${RED}🔴 Uninstalling OpenShift Console...${NC}"
            if [ -x "./openshift-console/scripts/uninstall-console.sh" ]; then
                ./openshift-console/scripts/uninstall-console.sh
            else
                ansible-playbook -i inventory/hosts.ini openshift-console/playbooks/uninstall.yml || true
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid Console action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_oracle() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🗄️ Deploying Oracle Database on K3s (Namespace: oracle)...${NC}"
            ansible-playbook -i inventory/hosts.ini oracle/playbooks/deploy.yml
            ;;
        uninstall|remove)
            echo -e "${RED}🗄️ Uninstalling Oracle Database (Namespace: oracle)...${NC}"
            ansible-playbook -i inventory/hosts.ini oracle/playbooks/uninstall.yml || true
            ;;
        *)
            echo -e "${RED}❌ Invalid Oracle action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_redis() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}⚡ Deploying Redis Cluster on K3s (Namespace: redis)...${NC}"
            ansible-playbook -i inventory/hosts.ini redis/playbooks/deploy.yml
            ;;
        uninstall|remove)
            echo -e "${RED}⚡ Uninstalling Redis Cluster (Namespace: redis)...${NC}"
            ansible-playbook -i inventory/hosts.ini redis/playbooks/uninstall.yml || true
            ;;
        *)
            echo -e "${RED}❌ Invalid Redis action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_redpanda() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🐼 Deploying Redpanda (Kafka) Cluster on K3s (Namespace: redpanda)...${NC}"
            ansible-playbook -i inventory/hosts.ini redpanda/playbooks/deploy.yml
            ;;
        uninstall|remove)
            echo -e "${RED}🐼 Uninstalling Redpanda Cluster (Namespace: redpanda)...${NC}"
            ansible-playbook -i inventory/hosts.ini redpanda/playbooks/uninstall.yml || true
            ;;
        *)
            echo -e "${RED}❌ Invalid Redpanda action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

cmd_minio() {
    local action="${1:-deploy}"
    print_banner
    case "$action" in
        deploy)
            echo -e "${GREEN}🪣 Deploying MinIO S3 Object Storage on K3s (Namespace: minio)...${NC}"
            ansible-playbook -i inventory/hosts.ini minio/playbooks/deploy.yml
            ;;
        uninstall|remove)
            echo -e "${RED}🪣 Uninstalling MinIO S3 Object Storage (Namespace: minio)...${NC}"
            ansible-playbook -i inventory/hosts.ini minio/playbooks/uninstall.yml || true
            ;;
        *)
            echo -e "${RED}❌ Invalid MinIO action: $action (use 'deploy' or 'uninstall')${NC}"
            exit 1
            ;;
    esac
}

interactive_menu() {
    while true; do
        clear
        print_banner
        echo -e "${BOLD}Select an operation:${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🌟 ${BOLD}Deploy Full Stack (Chạy Full luồng A-Z theo thứ tự chuẩn)${NC}"
        echo -e "  ${GREEN}2)${NC} 🎯 Bootstrap Control Plane (Chỉ Core K3s, MetalLB, Longhorn)"
        echo -e "  ${GREEN}3)${NC} ➕ Add Worker Node(s)"
        echo -e "  ${GREEN}4)${NC} ➖ Remove Worker Node"
        echo -e "  ${GREEN}5)${NC} 📊 Cluster Status & Health Check"
        echo -e "  ${GREEN}6)${NC} 💾 Backup Cluster"
        echo -e "  ${GREEN}7)${NC} 🔄 Restore Cluster"
        echo -e "  ${GREEN}8)${NC} 🐙 ArgoCD (Deploy / Uninstall)"
        echo -e "  ${GREEN}9)${NC} 🌐 KubeSphere (Deploy / Uninstall)"
        echo -e "  ${GREEN}10)${NC} 🔴 OpenShift Console (Deploy / Uninstall)"
        echo -e "  ${GREEN}11)${NC} 🗄️  Oracle Database (Deploy / Uninstall)"
        echo -e "  ${GREEN}12)${NC} ⚡ Redis Cluster (Deploy / Uninstall)"
        echo -e "  ${GREEN}13)${NC} 🐼 Redpanda / Kafka Cluster (Deploy / Uninstall)"
        echo -e "  ${GREEN}14)${NC} 🪣 MinIO S3 Storage (Deploy / Uninstall)"
        echo -e "  ${RED}15)${NC} 🗑️  Teardown Entire Cluster"
        echo -e "  ${CYAN}0)${NC} ❌ Exit"
        echo ""
        read -p "Enter choice [0-15]: " choice

        case $choice in
            1)
                echo -e "${YELLOW}Deploying Full Stack (Core ➜ Console ➜ Middlewares ➜ ArgoCD)...${NC}"
                cmd_deploy_all
                read -p "Press Enter to continue..."
                ;;
            2)
                read -p "Enter control node name [default: node-1]: " target_node
                target_node="${target_node:-node-1}"
                cmd_bootstrap "$target_node"
                read -p "Press Enter to continue..."
                ;;
            3)
                read -p "Enter worker node name(s) (space-separated, e.g. node-2 node-3): " worker_nodes
                if [ -n "$worker_nodes" ]; then
                    cmd_add_node $worker_nodes
                else
                    echo -e "${RED}No nodes specified.${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            4)
                read -p "Enter worker node name to remove (e.g. node-2): " worker_node
                if [ -n "$worker_node" ]; then
                    cmd_remove_node "$worker_node"
                else
                    echo -e "${RED}No node specified.${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            5)
                cmd_status
                read -p "Press Enter to continue..."
                ;;
            6)
                cmd_backup
                read -p "Press Enter to continue..."
                ;;
            7)
                read -p "Enter path to backup file: " backup_file
                if [ -n "$backup_file" ]; then
                    cmd_restore "$backup_file"
                else
                    echo -e "${RED}No backup file specified.${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            8)
                echo "1) Deploy ArgoCD"
                echo "2) Uninstall ArgoCD"
                read -p "Select ArgoCD action [1-2]: " argo_choice
                if [ "$argo_choice" == "1" ]; then
                    cmd_argocd deploy
                elif [ "$argo_choice" == "2" ]; then
                    cmd_argocd uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                echo "1) Deploy KubeSphere"
                echo "2) Uninstall KubeSphere"
                read -p "Select KubeSphere action [1-2]: " ks_choice
                if [ "$ks_choice" == "1" ]; then
                    cmd_kubesphere deploy
                elif [ "$ks_choice" == "2" ]; then
                    cmd_kubesphere uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            10)
                echo "1) Deploy OpenShift Console"
                echo "2) Uninstall OpenShift Console"
                read -p "Select Console action [1-2]: " oc_choice
                if [ "$oc_choice" == "1" ]; then
                    cmd_console deploy
                elif [ "$oc_choice" == "2" ]; then
                    cmd_console uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            11)
                echo "1) Deploy Oracle Database"
                echo "2) Uninstall Oracle Database"
                read -p "Select Oracle action [1-2]: " ora_choice
                if [ "$ora_choice" == "1" ]; then
                    cmd_oracle deploy
                elif [ "$ora_choice" == "2" ]; then
                    cmd_oracle uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            12)
                echo "1) Deploy Redis Cluster"
                echo "2) Uninstall Redis Cluster"
                read -p "Select Redis action [1-2]: " red_choice
                if [ "$red_choice" == "1" ]; then
                    cmd_redis deploy
                elif [ "$red_choice" == "2" ]; then
                    cmd_redis uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            13)
                echo "1) Deploy Redpanda Cluster"
                echo "2) Uninstall Redpanda Cluster"
                read -p "Select Redpanda action [1-2]: " rp_choice
                if [ "$rp_choice" == "1" ]; then
                    cmd_redpanda deploy
                elif [ "$rp_choice" == "2" ]; then
                    cmd_redpanda uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            14)
                echo "1) Deploy MinIO S3 Storage"
                echo "2) Uninstall MinIO S3 Storage"
                read -p "Select MinIO action [1-2]: " min_choice
                if [ "$min_choice" == "1" ]; then
                    cmd_minio deploy
                elif [ "$min_choice" == "2" ]; then
                    cmd_minio uninstall
                fi
                read -p "Press Enter to continue..."
                ;;
            15)
                echo -e "${RED}WARNING: This will completely destroy the cluster!${NC}"
                read -p "Type 'yes' to confirm: " confirm
                if [ "$confirm" == "yes" ]; then
                    cmd_teardown --all
                else
                    echo "Cancelled."
                fi
                read -p "Press Enter to continue..."
                ;;
            0)
                echo -e "${GREEN}Goodbye! 👋${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option.${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main Routing
ACTION="${1:-}"

if [ -z "$ACTION" ]; then
    interactive_menu
fi

shift || true

case "$ACTION" in
    deploy-all|all|full|full-deploy)
        cmd_deploy_all "$@"
        ;;
    bootstrap)
        cmd_bootstrap "$@"
        ;;
    teardown)
        cmd_teardown "$@"
        ;;
    add-node)
        cmd_add_node "$@"
        ;;
    remove-node)
        cmd_remove_node "$@"
        ;;
    status|check)
        cmd_status "$@"
        ;;
    backup)
        cmd_backup "$@"
        ;;
    restore)
        cmd_restore "$@"
        ;;
    argocd)
        cmd_argocd "$@"
        ;;
    kubesphere)
        cmd_kubesphere "$@"
        ;;
    console|openshift|openshift-console)
        cmd_console "$@"
        ;;
    oracle|oracledb)
        cmd_oracle "$@"
        ;;
    redis|redis-cluster)
        cmd_redis "$@"
        ;;
    redpanda|kafka)
        cmd_redpanda "$@"
        ;;
    minio|s3)
        cmd_minio "$@"
        ;;
    menu)
        interactive_menu
        ;;
    -h|--help|help)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $ACTION${NC}"
        show_help
        exit 1
        ;;
esac
