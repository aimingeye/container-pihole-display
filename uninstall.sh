#!/bin/bash
#
# Pi-hole Container Uninstall Script
# Completely removes Pi-hole and optionally removes container engine
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
DATA_DIR="/opt/pihole-data"

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
    echo -e "${RED}${BOLD}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║                                                       ║"
    echo "║           Pi-hole Container Uninstaller              ║"
    echo "║                                                       ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}${BOLD}WARNING: This will remove Pi-hole completely!${NC}"
    echo ""
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${CYAN}${prompt}${NC} [Y/n]: )" -r
        [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]
    else
        read -p "$(echo -e ${CYAN}${prompt}${NC} [y/N]: )" -r
        [[ "$REPLY" =~ ^[Yy]$ ]]
    fi
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root"
    echo "Please run: ${BOLD}sudo ./uninstall.sh${NC}"
    exit 1
fi

print_banner

# Final confirmation
if ! confirm "Are you sure you want to uninstall Pi-hole?" "n"; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""

# Load configuration if it exists
if [ -f "$INSTALL_DIR/pihole.conf" ]; then
    source "$INSTALL_DIR/pihole.conf"
    log_info "Configuration loaded"
else
    log_warn "Configuration not found, detecting container engine..."
    if command -v docker &> /dev/null && docker ps &> /dev/null 2>&1; then
        CONTAINER_ENGINE="docker"
    elif command -v podman &> /dev/null; then
        CONTAINER_ENGINE="podman"
    else
        CONTAINER_ENGINE="unknown"
    fi
fi

# Stop and remove container
log_step "Stopping Pi-hole"

# Stop systemd service
if systemctl is-active --quiet pihole-container.service; then
    log_info "Stopping Pi-hole service..."
    systemctl stop pihole-container.service 2>/dev/null || true
fi

systemctl disable pihole-container.service 2>/dev/null || true

# Stop and remove container
if [ -d "$INSTALL_DIR" ] && [ "$CONTAINER_ENGINE" != "unknown" ]; then
    cd "$INSTALL_DIR" || true
    
    if [ -f "docker-compose.yml" ]; then
        log_info "Removing Pi-hole container..."
        if [ "$CONTAINER_ENGINE" = "docker" ]; then
            docker-compose down 2>/dev/null || true
            docker rm -f pihole 2>/dev/null || true
        else
            podman-compose down 2>/dev/null || true
            podman rm -f pihole 2>/dev/null || true
        fi
    fi
fi

log_info "Pi-hole container stopped and removed"

# Remove systemd services
log_step "Removing System Services"

if [ -f /etc/systemd/system/pihole-container.service ]; then
    rm -f /etc/systemd/system/pihole-container.service
    log_info "Removed pihole-container.service"
fi

if [ -f /etc/systemd/system/pihole-display.service ]; then
    systemctl stop pihole-display.service 2>/dev/null || true
    systemctl disable pihole-display.service 2>/dev/null || true
    rm -f /etc/systemd/system/pihole-display.service
    log_info "Removed pihole-display.service"
fi

systemctl daemon-reload

# Remove display script
if [ -f /usr/local/bin/pihole-display ]; then
    rm -f /usr/local/bin/pihole-display
    log_info "Removed display script"
fi

# Ask about data removal
log_step "Data Removal"

echo ""
if confirm "Remove Pi-hole data (settings, blocklists, query history)?" "n"; then
    echo ""
    log_info "Removing Pi-hole data..."
    rm -rf "$DATA_DIR"
    log_info "Data removed from: $DATA_DIR"
else
    echo ""
    log_warn "Pi-hole data preserved at: $DATA_DIR"
    echo "  You can restore this data if you reinstall Pi-hole"
fi

# Remove installation directory
log_step "Removing Installation Files"

if [ -d "$INSTALL_DIR" ]; then
    # Backup config before removal
    if [ -f "$INSTALL_DIR/pihole.conf" ] && [ ! -d "$INSTALL_DIR/backups" ]; then
        mkdir -p /root/pihole-backup
        cp "$INSTALL_DIR/pihole.conf" /root/pihole-backup/pihole.conf.$(date +%Y%m%d)
        log_info "Configuration backed up to: /root/pihole-backup/"
    fi
    
    rm -rf "$INSTALL_DIR"
    log_info "Installation files removed from: $INSTALL_DIR"
fi

# Ask about container engine removal
if [ "$CONTAINER_ENGINE" != "unknown" ]; then
    log_step "Container Engine"
    
    echo ""
    echo -e "${CYAN}Container engine: ${BOLD}$CONTAINER_ENGINE${NC}"
    echo ""
    
    if confirm "Remove $CONTAINER_ENGINE?" "n"; then
        echo ""
        log_info "Removing $CONTAINER_ENGINE..."
        
        if [ "$CONTAINER_ENGINE" = "podman" ]; then
            apt-get remove -y podman podman-compose slirp4netns fuse-overlayfs 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            log_info "Podman removed"
        elif [ "$CONTAINER_ENGINE" = "docker" ]; then
            apt-get remove -y docker docker-compose docker.io 2>/dev/null || true
            apt-get autoremove -y 2>/dev/null || true
            log_info "Docker removed"
        fi
        
        # Clean up container storage
        if [ -d /var/lib/containers ]; then
            rm -rf /var/lib/containers
        fi
    else
        log_info "Keeping $CONTAINER_ENGINE installed"
    fi
fi

# Completion message
echo ""
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║                                                       ║"
echo "║       Pi-hole has been uninstalled successfully!     ║"
echo "║                                                       ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}${BOLD}Important Reminders:${NC}"
echo ""
echo "  1. Reset your router's DNS settings"
echo "     (Change from $SERVERIP to your ISP or public DNS)"
echo ""
echo "  2. Update DNS on devices you configured manually"
echo ""
echo "  3. Reboot devices or reconnect to WiFi to clear DNS cache"
echo ""
echo "  4. Consider restarting your router to ensure all changes take effect"
echo ""

if [ -d "$DATA_DIR" ]; then
    echo -e "${CYAN}Your Pi-hole data is still at: ${BOLD}$DATA_DIR${NC}"
    echo "You can manually remove it with: ${BOLD}sudo rm -rf $DATA_DIR${NC}"
    echo ""
fi

echo -e "${GREEN}Thank you for using Pi-hole!${NC}"
echo ""
