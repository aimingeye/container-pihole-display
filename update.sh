#!/bin/bash
#
# Pi-hole Container Update Script
# Updates Pi-hole to the latest version while preserving all settings
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/pihole-container"

# Logging functions
log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${CYAN}${BOLD}▶ $1${NC}"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║           Pi-hole Container Updater                  ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    echo "Please run: ${BOLD}sudo ./update.sh${NC}"
    exit 1
fi

print_banner

# Check if Pi-hole is installed
if [ ! -f "$INSTALL_DIR/pihole.conf" ]; then
    log_error "Pi-hole installation not found"
    log_error "Expected location: $INSTALL_DIR"
    echo ""
    echo "Have you installed Pi-hole yet?"
    echo "Run: ${BOLD}sudo ./install.sh${NC}"
    exit 1
fi

# Load configuration
log_step "Loading Configuration"
source "$INSTALL_DIR/pihole.conf"

if [ -z "$CONTAINER_ENGINE" ]; then
    log_error "Container engine not specified in config"
    log_error "Please check $INSTALL_DIR/pihole.conf"
    exit 1
fi

log_info "Container engine: $CONTAINER_ENGINE"
log_info "Pi-hole IP: $SERVERIP"

# Check if compose file exists
if [ ! -f "$INSTALL_DIR/docker-compose.yml" ]; then
    log_error "docker-compose.yml not found"
    exit 1
fi

# Backup check
log_step "Checking Backup"
if [ -d "$INSTALL_DIR/backups" ]; then
    log_info "Backup directory exists"
else
    log_info "Creating backup directory"
    mkdir -p "$INSTALL_DIR/backups"
fi

# Create backup
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$INSTALL_DIR/backups/pihole_${BACKUP_DATE}.tar.gz"

log_info "Creating backup: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" -C "$(dirname $DATA_DIR)" "$(basename $DATA_DIR)" 2>/dev/null || {
    log_warn "Backup failed, but continuing update"
}

# Change to install directory
cd "$INSTALL_DIR" || exit 1

# Update Pi-hole
log_step "Updating Pi-hole"

if [ "$CONTAINER_ENGINE" = "docker" ]; then
    log_info "Pulling latest Pi-hole image..."
    if docker-compose pull; then
        log_info "Image pulled successfully"
    else
        log_error "Failed to pull new image"
        exit 1
    fi
    
    log_info "Restarting Pi-hole..."
    docker-compose down
    docker-compose up -d
    
elif [ "$CONTAINER_ENGINE" = "podman" ]; then
    log_info "Pulling latest Pi-hole image..."
    if podman-compose pull; then
        log_info "Image pulled successfully"
    else
        log_error "Failed to pull new image"
        exit 1
    fi
    
    log_info "Restarting Pi-hole..."
    podman-compose down
    podman-compose up -d
else
    log_error "Unknown container engine: $CONTAINER_ENGINE"
    exit 1
fi

# Wait for Pi-hole to start
log_step "Waiting for Pi-hole"

MAX_WAIT=30
COUNT=0
while [ $COUNT -lt $MAX_WAIT ]; do
    if curl -s http://localhost/admin/ > /dev/null 2>&1; then
        log_info "Pi-hole is running!"
        break
    fi
    COUNT=$((COUNT + 1))
    sleep 2
    echo -ne "${CYAN}[⋯]${NC} Waiting... ($COUNT/$MAX_WAIT)\r"
done

if [ $COUNT -eq $MAX_WAIT ]; then
    log_warn "Pi-hole is taking longer than expected to start"
    log_warn "Check logs: $CONTAINER_ENGINE logs pihole"
fi

# Display version info
log_step "Update Complete"

if [ "$CONTAINER_ENGINE" = "docker" ]; then
    CONTAINER_VERSION=$(docker inspect pihole:latest 2>/dev/null | grep -o '"PIHOLE_DOCKER_TAG=[^"]*"' | cut -d= -f2 | tr -d '"' | head -1 || echo "unknown")
elif [ "$CONTAINER_ENGINE" = "podman" ]; then
    CONTAINER_VERSION=$(podman inspect pihole:latest 2>/dev/null | grep -o '"PIHOLE_DOCKER_TAG=[^"]*"' | cut -d= -f2 | tr -d '"' | head -1 || echo "unknown")
fi

echo ""
echo -e "${GREEN}${BOLD}Pi-hole has been updated successfully!${NC}"
echo ""
echo -e "${CYAN}Access Information:${NC}"
echo "  Web Interface: http://${SERVERIP}/admin"
echo "  Password:      ${WEBPASSWORD}"
echo ""
echo -e "${CYAN}Useful Commands:${NC}"
echo "  Status:  $CONTAINER_ENGINE ps"
echo "  Logs:    $CONTAINER_ENGINE logs pihole"
echo ""

# Cleanup old backups (keep last 5)
BACKUP_COUNT=$(ls -1 "$INSTALL_DIR/backups" 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    log_info "Cleaning up old backups (keeping 5 most recent)..."
    cd "$INSTALL_DIR/backups"
    ls -1t | tail -n +6 | xargs rm -f
fi

echo -e "${GREEN}Update complete!${NC}"
echo ""
