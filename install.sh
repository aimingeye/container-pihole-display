#!/bin/bash
#
# Pi-hole Container Installer for Raspberry Pi
# https://github.com/aimingeye/pi-hole-container
#
# One-command installation of Pi-hole in a container
# Optimized for Pi Zero 2W and all Raspberry Pi models
# Optional e-ink display support
#

set -e

VERSION="2.0.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
INSTALL_DIR="/opt/pihole-container"
DATA_DIR="/opt/pihole-data"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration
TIMEZONE=""
WEBPASSWORD=""
DNS1="1.1.1.1"
DNS2="1.0.0.1"
INTERFACE=""
SERVERIP=""
CONTAINER_ENGINE=""
INSTALL_DISPLAY=false
DISPLAY_TYPE=""
NON_INTERACTIVE=false
SKIP_WIFI=false
AUTO_CONFIRM=false

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║   ██████╗ ██╗      ██╗  ██╗ ██████╗ ██╗     ███████╗            ║
║   ██╔══██╗██║      ██║  ██║██╔═══██╗██║     ██╔════╝            ║
║   ██████╔╝██║█████╗███████║██║   ██║██║     █████╗              ║
║   ██╔═══╝ ██║╚════╝██╔══██║██║   ██║██║     ██╔══╝              ║
║   ██║     ██║      ██║  ██║╚██████╔╝███████╗███████╗            ║
║   ╚═╝     ╚═╝      ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝            ║
║                                                                   ║
║           Network-Wide Ad Blocking for Raspberry Pi              ║
║                  Optimized for Pi Zero 2W                        ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${GREEN}Version: ${VERSION}${NC}"
    echo ""
}

show_help() {
    cat << EOF
${BOLD}Pi-hole Container Installer${NC}

${BOLD}USAGE:${NC}
    sudo ./install.sh [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help              Show this help message
    -v, --version           Show version
    -y, --yes               Auto-confirm all prompts
    -n, --non-interactive   Non-interactive mode (uses all defaults)
    --display               Install e-ink display support
    --display-type TYPE     Display type (2.13, 2.7, 4.2)
    --timezone TZ           Set timezone (e.g., America/New_York)
    --password PASS         Set web interface password
    --dns-provider NUM      DNS provider (1=Cloudflare, 2=Google, 3=Quad9, 4=OpenDNS)
    --skip-wifi             Skip WiFi configuration
    --ip ADDRESS            Set static IP address
    --interface IFACE       Network interface (auto-detected if not set)

${BOLD}EXAMPLES:${NC}
    # Interactive installation (recommended for first time)
    sudo ./install.sh

    # Quick install with display support
    sudo ./install.sh -y --display --display-type 2.13

    # Non-interactive with custom settings
    sudo ./install.sh -n --password mypass123 --timezone America/Chicago

    # Install with specific DNS provider
    sudo ./install.sh --dns-provider 2

${BOLD}DOCUMENTATION:${NC}
    README.md        - Full documentation
    STATIC_IP.md     - Static IP configuration guide
    ROUTER_SETUP.md  - Router DNS configuration guide

${BOLD}SUPPORT:${NC}
    Issues: https://github.com/aimingeye/pi-hole-container/issues

EOF
    exit 0
}

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
    echo -e "${MAGENTA}${BOLD}▶ $1${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
}

log_progress() {
    echo -ne "${CYAN}[⋯]${NC} $1\r"
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} %s\r" "$spinstr" "$2"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "    \r"
}

confirm() {
    if [ "$AUTO_CONFIRM" = true ] || [ "$NON_INTERACTIVE" = true ]; then
        return 0
    fi
    local prompt="$1"
    local default="${2:-y}"
    
    if [ "$default" = "y" ]; then
        read -p "$(echo -e ${CYAN}${prompt}${NC} [Y/n]: )" -r
        [[ -z "$REPLY" || "$REPLY" =~ ^[Yy]$ ]]
    else
        read -p "$(echo -e ${CYAN}${prompt}${NC} [y/N]: )" -r
        [[ "$REPLY" =~ ^[Yy]$ ]]
    fi
}

# ============================================================================
# SYSTEM CHECKS
# ============================================================================

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        echo -e "${YELLOW}Please run: ${BOLD}sudo ./install.sh${NC}"
        exit 1
    fi
}

detect_pi_model() {
    if [ ! -f /proc/device-tree/model ]; then
        echo "unknown"
        return
    fi
    
    local model=$(cat /proc/device-tree/model)
    
    if echo "$model" | grep -qi "Pi Zero 2"; then
        echo "zero2"
    elif echo "$model" | grep -qi "Pi Zero"; then
        echo "zero"
    elif echo "$model" | grep -qi "Pi 1"; then
        echo "1"
    elif echo "$model" | grep -qi "Pi 2"; then
        echo "2"
    elif echo "$model" | grep -qi "Pi 3"; then
        echo "3"
    elif echo "$model" | grep -qi "Pi 4"; then
        echo "4"
    elif echo "$model" | grep -qi "Pi 5"; then
        echo "5"
    else
        echo "unknown"
    fi
}

check_raspberry_pi() {
    log_step "Detecting Raspberry Pi"
    
    if [ ! -f /proc/device-tree/model ]; then
        log_warn "Cannot detect Raspberry Pi model"
        log_warn "This script is optimized for Raspberry Pi but will continue anyway"
        return 0
    fi
    
    local model=$(cat /proc/device-tree/model)
    local pi_model=$(detect_pi_model)
    
    log_info "Detected: $model"
    
    case $pi_model in
        zero2)
            log_info "Pi Zero 2W detected - Applying optimizations"
            ;;
        zero)
            log_info "Pi Zero detected - Applying optimizations"
            log_warn "Pi Zero W (original) may be slow. Pi Zero 2W recommended"
            ;;
        1)
            log_info "Pi 1 detected - Applying optimizations"
            ;;
        2|3)
            log_info "Excellent choice for Pi-hole!"
            ;;
        4|5)
            log_info "High performance Pi detected - Optimal for Pi-hole!"
            ;;
        *)
            log_warn "Unknown Pi model, using default settings"
            ;;
    esac
    
    echo ""
}

check_system_resources() {
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    local free_disk=$(df -m / | awk 'NR==2 {print $4}')
    
    log_info "System resources:"
    echo "  RAM: ${total_mem}MB"
    echo "  Free disk: ${free_disk}MB"
    
    if [ "$total_mem" -lt 256 ]; then
        log_warn "Low memory detected (${total_mem}MB). 512MB+ recommended"
    fi
    
    if [ "$free_disk" -lt 1000 ]; then
        log_warn "Low disk space (${free_disk}MB). 2GB+ recommended"
        if ! confirm "Continue with low disk space?" "n"; then
            exit 1
        fi
    fi
}

# ============================================================================
# NETWORK DETECTION
# ============================================================================

detect_interface() {
    log_step "Detecting Network Interface"
    
    if [ -n "$INTERFACE" ]; then
        log_info "Using specified interface: $INTERFACE"
        return 0
    fi
    
    # Try to find the primary interface
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    
    if [ -n "$INTERFACE" ]; then
        log_info "Detected active interface: $INTERFACE"
        return 0
    fi
    
    # Fallback: find any active interface
    INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v '^lo$' | head -n1)
    
    if [ -n "$INTERFACE" ]; then
        log_warn "No default route found, using: $INTERFACE"
    else
        log_error "No network interface detected"
        exit 1
    fi
}

detect_server_ip() {
    log_step "Detecting IP Address"
    
    if [ -n "$SERVERIP" ]; then
        log_info "Using specified IP: $SERVERIP"
        return 0
    fi
    
    SERVERIP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)
    
    if [ -n "$SERVERIP" ]; then
        log_info "Detected IP: $SERVERIP on $INTERFACE"
    else
        log_error "Could not detect IP address for $INTERFACE"
        read -p "Enter your Pi's IP address manually: " SERVERIP
        if [ -z "$SERVERIP" ]; then
            log_error "IP address required"
            exit 1
        fi
    fi
}

check_internet() {
    log_progress "Checking internet connection..."
    
    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        log_info "Internet connection: OK"
        return 0
    else
        log_warn "No internet connection detected"
        if ! confirm "Continue without internet connection?" "n"; then
            exit 1
        fi
    fi
}

# ============================================================================
# CONFIGURATION
# ============================================================================

prompt_configuration() {
    if [ "$NON_INTERACTIVE" = true ]; then
        log_info "Non-interactive mode - using defaults"
        return 0
    fi
    
    log_step "Configuration"
    
    # Timezone
    if [ -z "$TIMEZONE" ]; then
        local current_tz=$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Unknown")
        echo -e "${CYAN}Current timezone: ${BOLD}$current_tz${NC}"
        
        if confirm "Use this timezone?" "y"; then
            TIMEZONE="$current_tz"
        else
            read -p "Enter timezone (e.g., America/New_York): " TIMEZONE
            if [ -z "$TIMEZONE" ]; then
                TIMEZONE="$current_tz"
            fi
        fi
    fi
    
    log_info "Timezone: $TIMEZONE"
    echo ""
    
    # Web Password
    if [ -z "$WEBPASSWORD" ]; then
        echo -e "${CYAN}${BOLD}Web Interface Password${NC}"
        read -sp "Enter password (or press Enter for random): " WEBPASSWORD
        echo ""
        
        if [ -z "$WEBPASSWORD" ]; then
            WEBPASSWORD=$(openssl rand -base64 12 2>/dev/null || tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
            log_info "Generated random password"
        fi
    fi
    echo ""
    
    # DNS Provider
    if [ -z "$DNS1" ] || [ "$DNS1" = "1.1.1.1" ]; then
        echo -e "${CYAN}${BOLD}Upstream DNS Provider:${NC}"
        echo "  1) Cloudflare (1.1.1.1) - Fast, privacy-focused [default]"
        echo "  2) Google (8.8.8.8) - Fast, reliable"
        echo "  3) Quad9 (9.9.9.9) - Security-focused, blocks malware"
        echo "  4) OpenDNS (208.67.222.222) - Family-safe options"
        echo "  5) Custom"
        read -p "Select [1-5] (default: 1): " dns_choice
        echo ""
        
        case ${dns_choice:-1} in
            1) DNS1="1.1.1.1"; DNS2="1.0.0.1"; log_info "Using Cloudflare DNS" ;;
            2) DNS1="8.8.8.8"; DNS2="8.8.4.4"; log_info "Using Google DNS" ;;
            3) DNS1="9.9.9.9"; DNS2="149.112.112.112"; log_info "Using Quad9 DNS" ;;
            4) DNS1="208.67.222.222"; DNS2="208.67.220.220"; log_info "Using OpenDNS" ;;
            5)
                read -p "Primary DNS: " DNS1
                read -p "Secondary DNS: " DNS2
                log_info "Using custom DNS: $DNS1, $DNS2"
                ;;
            *) DNS1="1.1.1.1"; DNS2="1.0.0.1"; log_info "Using Cloudflare DNS (default)" ;;
        esac
    fi
    echo ""
    
    # Display installation
    if [ "$INSTALL_DISPLAY" = false ]; then
        if confirm "Install e-ink display support?" "n"; then
            INSTALL_DISPLAY=true
            
            echo ""
            echo -e "${CYAN}${BOLD}E-ink Display Type:${NC}"
            echo "  1) Waveshare 2.13 inch"
            echo "  2) Waveshare 2.7 inch"
            echo "  3) Waveshare 4.2 inch"
            echo "  4) Other/Skip hardware config"
            read -p "Select [1-4]: " display_choice
            
            case $display_choice in
                1) DISPLAY_TYPE="2.13" ;;
                2) DISPLAY_TYPE="2.7" ;;
                3) DISPLAY_TYPE="4.2" ;;
                *) DISPLAY_TYPE="other" ;;
            esac
            
            log_info "Display type: $DISPLAY_TYPE"
            echo ""
        fi
    fi
}

# ============================================================================
# CONTAINER ENGINE
# ============================================================================

setup_container_engine() {
    log_step "Container Engine Setup"
    
    # Check for existing engines
    if command -v docker &> /dev/null && docker ps &> /dev/null 2>&1; then
        CONTAINER_ENGINE="docker"
        log_info "Docker detected and working"
        return 0
    elif command -v podman &> /dev/null; then
        CONTAINER_ENGINE="podman"
        log_info "Podman detected"
        return 0
    fi
    
    # Install Podman
    log_info "No container engine found - Installing Podman"
    log_info "Podman is lightweight and perfect for Raspberry Pi"
    echo ""
    
    if ! confirm "Install Podman?" "y"; then
        log_error "Container engine required for Pi-hole"
        exit 1
    fi
    
    install_podman
}

install_podman() {
    log_info "Installing Podman and dependencies..."
    
    # Update quietly
    log_progress "Updating package lists..."
    apt-get update -qq > /dev/null 2>&1 || {
        log_error "Failed to update package lists"
        return 1
    }
    log_info "Package lists updated"
    
    # Install Podman
    log_progress "Installing Podman..."
    if apt-get install -y -qq podman slirp4netns fuse-overlayfs uidmap > /dev/null 2>&1; then
        log_info "Podman installed successfully"
    else
        log_error "Failed to install Podman"
        return 1
    fi
    
    # Install podman-compose
    log_progress "Installing podman-compose..."
    if apt-get install -y -qq podman-compose > /dev/null 2>&1; then
        log_info "podman-compose installed"
    else
        log_warn "podman-compose not in repos, installing via pip..."
        apt-get install -y -qq python3-pip python3-setuptools > /dev/null 2>&1 || true
        pip3 install --break-system-packages podman-compose > /dev/null 2>&1 || pip3 install podman-compose > /dev/null 2>&1 || true
    fi
    
    CONTAINER_ENGINE="podman"
    optimize_podman
}

optimize_podman() {
    local pi_model=$(detect_pi_model)
    log_info "Optimizing Podman for $pi_model..."
    
    mkdir -p /etc/containers
    
    # Optimized storage config
    cat > /etc/containers/storage.conf << 'EOF'
[storage]
driver = "overlay"
runroot = "/run/containers/storage"
graphroot = "/var/lib/containers/storage"

[storage.options]
size = ""

[storage.options.overlay]
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev,metacopy=on"
EOF

    # Optimized containers config
    cat > /etc/containers/containers.conf << 'EOF'
[containers]
default_ulimits = ["nofile=1024:2048"]

[engine]
cgroup_manager = "systemd"
events_logger = "file"
runtime = "crun"
network_cmd_options = ["enable_ipv6=false"]
EOF

    # Pi Zero / Pi Zero 2W specific optimizations
    if [ "$pi_model" = "zero" ] || [ "$pi_model" = "zero2" ] || [ "$pi_model" = "1" ]; then
        log_info "Applying low-memory device optimizations..."
        
        echo '[containers]' >> /etc/containers/containers.conf
        echo 'image_parallel_copies = 1' >> /etc/containers/containers.conf
        
        # Add swap if not present
        if [ ! -f /swapfile ] && [ ! -f /var/swap ]; then
            log_info "Creating swap file (512MB) for better performance..."
            dd if=/dev/zero of=/swapfile bs=1M count=512 status=none 2>/dev/null || true
            chmod 600 /swapfile
            mkswap /swapfile > /dev/null 2>&1 || true
            swapon /swapfile 2>/dev/null || true
            if ! grep -q '/swapfile' /etc/fstab; then
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
            fi
            log_info "Swap file created"
        fi
    fi
    
    log_info "Podman optimization complete"
}

# ============================================================================
# PORT CHECKS
# ============================================================================

check_ports() {
    log_step "Checking Required Ports"
    
    if ! command -v lsof &> /dev/null; then
        apt-get install -y -qq lsof 2>/dev/null || {
            log_warn "Could not install lsof, skipping port check"
            return 0
        }
    fi
    
    local ports_in_use=()
    local processes=()
    
    # Check port 53 (DNS)
    if lsof -i :53 -sTCP:LISTEN -t >/dev/null 2>&1 || lsof -i :53 -sUDP:LISTEN -t >/dev/null 2>&1; then
        local proc=$(lsof -i :53 -sTCP:LISTEN -t -c systemd-resolved -c dnsmasq 2>/dev/null | head -1)
        ports_in_use+=("53 (DNS)")
        if [ -n "$proc" ]; then
            processes+=("Port 53: $(ps -p $proc -o comm= 2>/dev/null || echo 'unknown')")
        fi
    fi
    
    # Check port 80 (HTTP)
    if lsof -i :80 -sTCP:LISTEN -t >/dev/null 2>&1; then
        local proc=$(lsof -i :80 -sTCP:LISTEN -t 2>/dev/null | head -1)
        ports_in_use+=("80 (HTTP)")
        if [ -n "$proc" ]; then
            processes+=("Port 80: $(ps -p $proc -o comm= 2>/dev/null || echo 'unknown')")
        fi
    fi
    
    if [ ${#ports_in_use[@]} -gt 0 ]; then
        log_warn "Required ports are in use: ${ports_in_use[*]}"
        for proc in "${processes[@]}"; do
            echo "  - $proc"
        done
        echo ""
        log_info "Common fixes:"
        echo "  • Port 53: sudo systemctl disable --now systemd-resolved"
        echo "  • Port 80: sudo systemctl stop apache2/nginx"
        echo ""
        
        if ! confirm "Continue anyway?" "n"; then
            log_error "Installation cancelled. Please free up the required ports."
            exit 1
        fi
    else
        log_info "All required ports (53, 80) are available"
    fi
}

# ============================================================================
# PI-HOLE INSTALLATION
# ============================================================================

create_directories() {
    log_step "Creating Directories"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DATA_DIR/etc-pihole"
    mkdir -p "$DATA_DIR/etc-dnsmasq.d"
    
    log_info "Created: $INSTALL_DIR"
    log_info "Created: $DATA_DIR"
}

create_compose_file() {
    log_step "Creating Pi-hole Configuration"
    
    if [ -z "$WEBPASSWORD" ]; then
        WEBPASSWORD=$(openssl rand -base64 12 2>/dev/null || tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)
    fi
    
    cat > "$INSTALL_DIR/docker-compose.yml" << EOF
version: "3"

services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    hostname: pihole
    restart: unless-stopped
    
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "80:80/tcp"
    
    environment:
      TZ: '${TIMEZONE}'
      WEBPASSWORD: '${WEBPASSWORD}'
      SERVERIP: '${SERVERIP}'
      DNS1: '${DNS1}'
      DNS2: '${DNS2}'
      INTERFACE: '${INTERFACE}'
      DNSMASQ_LISTENING: 'all'
      PIHOLE_DNS_: '${DNS1};${DNS2}'
      VIRTUAL_HOST: 'pihole.local'
      FTLCONF_LOCAL_IPV4: '${SERVERIP}'
      
    volumes:
      - '${DATA_DIR}/etc-pihole:/etc/pihole'
      - '${DATA_DIR}/etc-dnsmasq.d:/etc/dnsmasq.d'
    
    cap_add:
      - NET_ADMIN
    
    dns:
      - 127.0.0.1
      - ${DNS1}
EOF

    log_info "Configuration file created"
}

create_systemd_service() {
    log_step "Creating System Service"
    
    local compose_cmd="docker-compose"
    if [ "$CONTAINER_ENGINE" = "podman" ]; then
        compose_cmd="podman-compose"
    fi
    
    local compose_path=$(which "$compose_cmd" 2>/dev/null || echo "/usr/bin/${compose_cmd}")
    
    cat > /etc/systemd/system/pihole-container.service << EOF
[Unit]
Description=Pi-hole Container Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStart=${compose_path} up -d
ExecStop=${compose_path} down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_info "System service created"
}

pull_and_start_pihole() {
    log_step "Downloading and Starting Pi-hole"
    
    local pi_model=$(detect_pi_model)
    if [ "$pi_model" = "zero" ] || [ "$pi_model" = "zero2" ]; then
        log_info "This may take 5-10 minutes on Pi Zero..."
    else
        log_info "This may take a few minutes..."
    fi
    
    cd "$INSTALL_DIR"
    
    log_progress "Pulling Pi-hole container image..."
    if [ "$CONTAINER_ENGINE" = "docker" ]; then
        if docker-compose pull > /tmp/pihole-pull.log 2>&1; then
            log_info "Pi-hole image downloaded"
        else
            log_error "Failed to pull image. Check /tmp/pihole-pull.log"
            tail -20 /tmp/pihole-pull.log
            exit 1
        fi
    else
        if podman-compose pull > /tmp/pihole-pull.log 2>&1; then
            log_info "Pi-hole image downloaded"
        else
            log_error "Failed to pull image. Check /tmp/pihole-pull.log"
            tail -20 /tmp/pihole-pull.log
            exit 1
        fi
    fi
    
    log_progress "Starting Pi-hole container..."
    if [ "$CONTAINER_ENGINE" = "docker" ]; then
        docker-compose up -d > /tmp/pihole-start.log 2>&1
    else
        podman-compose up -d > /tmp/pihole-start.log 2>&1
    fi
    
    log_info "Pi-hole container started"
    
    # Enable auto-start
    systemctl enable pihole-container.service > /dev/null 2>&1
    log_info "Auto-start on boot enabled"
}

wait_for_pihole() {
    log_step "Waiting for Pi-hole to Initialize"
    
    local max_attempts=60
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s http://localhost/admin/ > /dev/null 2>&1; then
            log_info "Pi-hole is ready!"
            return 0
        fi
        
        attempt=$((attempt + 1))
        sleep 2
        log_progress "Waiting for Pi-hole... ($attempt/$max_attempts)"
    done
    
    log_warn "Pi-hole is taking longer than expected"
    log_warn "Check status with: $CONTAINER_ENGINE logs pihole"
}

save_config() {
    log_step "Saving Configuration"
    
    cat > "$INSTALL_DIR/pihole.conf" << EOF
# Pi-hole Container Configuration
# Generated: $(date)
# Installer Version: ${VERSION}

TIMEZONE="${TIMEZONE}"
WEBPASSWORD="${WEBPASSWORD}"
DNS1="${DNS1}"
DNS2="${DNS2}"
INTERFACE="${INTERFACE}"
SERVERIP="${SERVERIP}"
CONTAINER_ENGINE="${CONTAINER_ENGINE}"
PI_MODEL="$(detect_pi_model)"
DISPLAY_INSTALLED="${INSTALL_DISPLAY}"
EOF

    chmod 600 "$INSTALL_DIR/pihole.conf"
    log_info "Configuration saved: $INSTALL_DIR/pihole.conf"
}

# ============================================================================
# DISPLAY INSTALLATION
# ============================================================================

install_display() {
    if [ "$INSTALL_DISPLAY" = false ]; then
        return 0
    fi
    
    log_step "Installing E-ink Display Support"
    
    # Install Python dependencies
    log_info "Installing Python dependencies..."
    apt-get install -y -qq python3-pip python3-pil python3-numpy fonts-dejavu > /dev/null 2>&1 || {
        log_error "Failed to install display dependencies"
        return 1
    }
    
    # Install Python packages
    pip3 install --break-system-packages requests pillow > /dev/null 2>&1 || pip3 install requests pillow > /dev/null 2>&1 || {
        log_error "Failed to install Python packages"
        return 1
    }
    
    # Install Waveshare library if specified
    if [ "$DISPLAY_TYPE" != "other" ]; then
        log_info "Installing Waveshare e-ink library..."
        pip3 install --break-system-packages waveshare-epd > /dev/null 2>&1 || pip3 install waveshare-epd > /dev/null 2>&1 || {
            log_warn "Failed to install Waveshare library"
        }
    fi
    
    # Copy display script
    if [ -f "$SCRIPT_DIR/pihole-display.py" ]; then
        cp "$SCRIPT_DIR/pihole-display.py" /usr/local/bin/pihole-display
        chmod +x /usr/local/bin/pihole-display
        log_info "Display script installed"
    else
        log_warn "pihole-display.py not found, skipping"
        return 0
    fi
    
    # Create systemd service for display
    cat > /etc/systemd/system/pihole-display.service << 'EOF'
[Unit]
Description=Pi-hole E-ink Display Service
After=network.target pihole-container.service
Wants=pihole-container.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/python3 /usr/local/bin/pihole-display
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable pihole-display.service > /dev/null 2>&1
    
    log_info "Display service created and enabled"
    log_info "Start with: sudo systemctl start pihole-display"
}

# ============================================================================
# COMPLETION
# ============================================================================

display_completion() {
    clear
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════════╗
║                                                                   ║
║                    Installation Complete!                        ║
║                                                                   ║
╚═══════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}${BOLD}ACCESS INFORMATION${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  Web Interface: ${BOLD}http://${SERVERIP}/admin${NC}"
    echo -e "  Password:      ${BOLD}${WEBPASSWORD}${NC}"
    echo -e "  DNS Server:    ${BOLD}${SERVERIP}${NC}"
    echo ""
    
    echo -e "${CYAN}${BOLD}NEXT STEPS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  1. Configure static IP (see STATIC_IP.md)"
    echo "  2. Set your router's DNS to ${SERVERIP} (see ROUTER_SETUP.md)"
    echo "  3. Or configure DNS on individual devices"
    echo ""
    
    echo -e "${CYAN}${BOLD}USEFUL COMMANDS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if [ "$CONTAINER_ENGINE" = "docker" ]; then
        echo "  Status:        docker ps"
        echo "  Logs:          docker logs pihole"
        echo "  Restart:       cd ${INSTALL_DIR} && docker-compose restart"
        echo "  Service:       systemctl status pihole-container"
    else
        echo "  Status:        podman ps"
        echo "  Logs:          podman logs pihole"
        echo "  Restart:       cd ${INSTALL_DIR} && podman-compose restart"
        echo "  Service:       systemctl status pihole-container"
    fi
    echo "  Update:        sudo ./update.sh"
    echo "  Uninstall:     sudo ./uninstall.sh"
    
    if [ "$INSTALL_DISPLAY" = true ]; then
        echo ""
        echo -e "${CYAN}${BOLD}DISPLAY COMMANDS${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "  Start display: sudo systemctl start pihole-display"
        echo "  Stop display:  sudo systemctl stop pihole-display"
        echo "  Display logs:  sudo journalctl -u pihole-display -f"
    fi
    
    echo ""
    echo -e "${MAGENTA}${BOLD}DOCUMENTATION${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "  README.md        - Full documentation"
    echo "  STATIC_IP.md     - Static IP configuration guide"
    echo "  ROUTER_SETUP.md  - Router DNS setup guide"
    echo ""
    
    echo -e "${GREEN}${BOLD}Thank you for using Pi-hole Container Installer!${NC}"
    echo -e "${BLUE}Report issues: https://github.com/aimingeye/pi-hole-container/issues${NC}"
    echo ""
}

# ============================================================================
# MAIN INSTALLATION FLOW
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -v|--version)
                echo "Pi-hole Container Installer v${VERSION}"
                exit 0
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -n|--non-interactive)
                NON_INTERACTIVE=true
                AUTO_CONFIRM=true
                shift
                ;;
            --display)
                INSTALL_DISPLAY=true
                shift
                ;;
            --display-type)
                DISPLAY_TYPE="$2"
                shift 2
                ;;
            --timezone)
                TIMEZONE="$2"
                shift 2
                ;;
            --password)
                WEBPASSWORD="$2"
                shift 2
                ;;
            --dns-provider)
                case $2 in
                    1) DNS1="1.1.1.1"; DNS2="1.0.0.1" ;;
                    2) DNS1="8.8.8.8"; DNS2="8.8.4.4" ;;
                    3) DNS1="9.9.9.9"; DNS2="149.112.112.112" ;;
                    4) DNS1="208.67.222.222"; DNS2="208.67.220.220" ;;
                esac
                shift 2
                ;;
            --skip-wifi)
                SKIP_WIFI=true
                shift
                ;;
            --ip)
                SERVERIP="$2"
                shift 2
                ;;
            --interface)
                INTERFACE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Run './install.sh --help' for usage"
                exit 1
                ;;
        esac
    done
}

main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show banner
    print_banner
    
    # Pre-flight checks
    check_root
    check_raspberry_pi
    check_system_resources
    check_internet
    
    # Configuration
    prompt_configuration
    
    # Network setup
    detect_interface
    detect_server_ip
    check_ports
    
    # Installation
    setup_container_engine
    create_directories
    create_compose_file
    create_systemd_service
    pull_and_start_pihole
    wait_for_pihole
    
    # Optional display
    install_display
    
    # Finalize
    save_config
    display_completion
}

# Run main installation
main "$@"
