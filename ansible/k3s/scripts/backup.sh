#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
BACKUP_TYPE="full"
INVENTORY_FILE="../inventory/hosts.ini"
PLAYBOOK_DIR="../playbooks"

# Help
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Backup K3s cluster (ETCD snapshots and Longhorn volumes)

OPTIONS:
    -t, --type TYPE        Backup type: full, etcd, longhorn (default: full)
    -i, --inventory FILE   Ansible inventory file (default: ../inventory/hosts.ini)
    -h, --help            Show this help

EXAMPLES:
    # Full backup (ETCD + Longhorn)
    $(basename "$0")

    # ETCD only
    $(basename "$0") -t etcd

    # Longhorn only
    $(basename "$0") -t longhorn

    # Custom inventory
    $(basename "$0") -i /path/to/hosts.ini

EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BACKUP_TYPE="$2"
            shift 2
            ;;
        -i|--inventory)
            INVENTORY_FILE="$2"
            shift 2
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

# Validate backup type
if [[ ! "$BACKUP_TYPE" =~ ^(full|etcd|longhorn)$ ]]; then
    echo -e "${RED}Invalid backup type: $BACKUP_TYPE${NC}"
    echo "Valid types: full, etcd, longhorn"
    exit 1
fi

# Check inventory exists
if [ ! -f "$INVENTORY_FILE" ]; then
    echo -e "${RED}Inventory file not found: $INVENTORY_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Starting K3s backup...${NC}"
echo "Backup type: $BACKUP_TYPE"
echo "Inventory: $INVENTORY_FILE"
echo ""

# Run backup playbook
cd "$PLAYBOOK_DIR"

case "$BACKUP_TYPE" in
    full)
        echo -e "${YELLOW}Running full backup (ETCD + Longhorn)${NC}"
        ansible-playbook -i "$INVENTORY_FILE" 10-backup.yml
        ;;
    etcd)
        echo -e "${YELLOW}Running ETCD backup${NC}"
        ansible-playbook -i "$INVENTORY_FILE" 10-backup.yml --tags etcd
        ;;
    longhorn)
        echo -e "${YELLOW}Running Longhorn backup${NC}"
        ansible-playbook -i "$INVENTORY_FILE" 10-backup.yml --tags longhorn
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Backup completed successfully!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}Backup failed!${NC}"
    exit 1
fi
