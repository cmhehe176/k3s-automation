#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
INVENTORY_FILE="../inventory/hosts.ini"
PLAYBOOK_DIR="../playbooks"
BACKUP_DIR="/var/backups/k3s/etcd"

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Restore K3s cluster from ETCD snapshot

OPTIONS:
    -s, --snapshot FILE    Snapshot filename (required)
    -i, --inventory FILE   Ansible inventory file (default: ../inventory/hosts.ini)
    -l, --list            List available snapshots
    -y, --yes             Skip confirmation prompt
    -h, --help            Show this help

EXAMPLES:
    # List available snapshots
    $(basename "$0") -l

    # Restore from snapshot
    $(basename "$0") -s backup-20260817T120000

    # Restore without confirmation
    $(basename "$0") -s backup-20260817T120000 -y

    # Custom inventory
    $(basename "$0") -s backup-20260817T120000 -i /path/to/hosts.ini

EOF
}

# List snapshots
list_snapshots() {
    echo -e "${GREEN}Listing available ETCD snapshots...${NC}"
    echo ""

    # Get first control node from inventory
    CONTROL_NODE=$(grep -A 10 "\[k3s_control\]" "$INVENTORY_FILE" | grep -v "\[" | grep -v "^$" | head -1 | awk '{print $1}')

    if [ -z "$CONTROL_NODE" ]; then
        echo -e "${RED}No control node found in inventory${NC}"
        exit 1
    fi

    echo "Snapshots on $CONTROL_NODE:"
    ssh "$CONTROL_NODE" "ls -lh $BACKUP_DIR 2>/dev/null || echo 'No snapshots found'" | grep -v "^total"
    echo ""

    exit 0
}

# Parse args
SNAPSHOT_FILE=""
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--snapshot)
            SNAPSHOT_FILE="$2"
            shift 2
            ;;
        -i|--inventory)
            INVENTORY_FILE="$2"
            shift 2
            ;;
        -l|--list)
            list_snapshots
            ;;
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate
if [ -z "$SNAPSHOT_FILE" ]; then
    echo -e "${RED}Snapshot file is required${NC}"
    echo ""
    show_help
    exit 1
fi

if [ ! -f "$INVENTORY_FILE" ]; then
    echo -e "${RED}Inventory file not found: $INVENTORY_FILE${NC}"
    exit 1
fi

# Confirmation
if [ "$SKIP_CONFIRM" = false ]; then
    echo -e "${YELLOW}WARNING: This will restore K3s cluster from ETCD snapshot${NC}"
    echo "Snapshot: $SNAPSHOT_FILE"
    echo "Current cluster state will be replaced"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo -e "${YELLOW}Restore cancelled${NC}"
        exit 0
    fi
fi

echo -e "${GREEN}Starting K3s restore...${NC}"
echo "Snapshot: $SNAPSHOT_FILE"
echo "Inventory: $INVENTORY_FILE"
echo ""

# Run restore playbook
cd "$PLAYBOOK_DIR"

if [ "$SKIP_CONFIRM" = true ]; then
    ansible-playbook -i "$INVENTORY_FILE" 11-restore.yml \
        -e "snapshot_file=$SNAPSHOT_FILE" \
        -e "confirm_restore=true"
else
    ansible-playbook -i "$INVENTORY_FILE" 11-restore.yml \
        -e "snapshot_file=$SNAPSHOT_FILE"
fi

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Restore completed successfully!${NC}"
    echo -e "${YELLOW}NOTE: You may need to restart worker nodes if they don't rejoin automatically${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Restore failed!${NC}"
    exit 1
fi
