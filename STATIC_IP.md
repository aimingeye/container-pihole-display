# Static IP Configuration Guide

Setting up a static IP address ensures your Pi-hole always has the same IP address, which is essential for DNS configuration.

## Table of Contents

- [Why Static IP?](#why-static-ip)
- [Method 1: Using nmtui (Recommended)](#method-1-using-nmtui-recommended)
- [Method 2: Using dhcpcd (Traditional)](#method-2-using-dhcpcd-traditional)
- [Method 3: Router DHCP Reservation](#method-3-router-dhcp-reservation)
- [Method 4: NetworkManager CLI](#method-4-networkmanager-cli)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Why Static IP?

Your Pi-hole needs a static (fixed) IP address because:

- Clients need a consistent DNS server address
- Prevents DNS resolution failure if IP changes
- Router configuration requires a fixed IP
- Avoids service interruption

## Method 1: Using nmtui (Recommended)

This is the easiest method for Raspberry Pi OS Bullseye and newer.

### Step 1: Launch nmtui

```bash
sudo nmtui
```

### Step 2: Navigate the Interface

1. Select **"Edit a connection"**
2. Choose your network connection (usually `eth0` for Ethernet or `wlan0` for Wi-Fi)
3. Press `Enter` to edit

### Step 3: Configure IPv4

1. Scroll down to **"IPv4 CONFIGURATION"**
2. Change from `<Automatic>` to `<Manual>`
3. Select **"Show"** next to Addresses
4. Click **"Add"** and enter your desired IP configuration:

```
Address:  192.168.1.100/24
Gateway:  192.168.1.1
DNS:      1.1.1.1,1.0.0.1
```

**Example Values (adjust for your network):**

| Field | Example | Description |
|-------|---------|-------------|
| Address | `192.168.1.100/24` | Your desired static IP + subnet mask |
| Gateway | `192.168.1.1` | Your router's IP address |
| DNS | `1.1.1.1,1.0.0.1` | Upstream DNS servers (Cloudflare) |

### Step 4: Save and Exit

1. Press `Tab` to navigate to **"OK"** and press `Enter`
2. Go back to the main menu
3. Select **"Activate a connection"**
4. Deactivate and reactivate your connection
5. Select **"Quit"**

### Step 5: Reboot

```bash
sudo reboot
```

## Method 2: Using dhcpcd (Traditional)

This method works on older Raspberry Pi OS versions and provides more control.

### Step 1: Identify Your Network Info

```bash
# Check current IP configuration
ip addr show

# Check your gateway
ip route | grep default

# Check your network interface name
ip link show
```

### Step 2: Edit dhcpcd Configuration

```bash
sudo nano /etc/dhcpcd.conf
```

### Step 3: Add Static IP Configuration

Add these lines at the **bottom** of the file:

**For Ethernet (eth0):**

```bash
# Static IP configuration for eth0
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=1.1.1.1 1.0.0.1
```

**For Wi-Fi (wlan0):**

```bash
# Static IP configuration for wlan0
interface wlan0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=1.1.1.1 1.0.0.1
```

### Step 4: Save and Restart

```bash
# Save: Ctrl+X, then Y, then Enter

# Restart networking
sudo systemctl restart dhcpcd

# Or reboot
sudo reboot
```

## Method 3: Router DHCP Reservation

Configure your router to always give your Pi the same IP address.

### Advantages
- No changes needed on the Pi
- Centralized network management
- Works across OS reinstalls

### Steps (General)

1. **Find Pi's MAC Address:**

```bash
ip link show eth0 | grep link/ether
# Example output: link/ether dc:a6:32:12:34:56
```

2. **Access Router Admin Panel:**
   - Open browser
   - Go to router IP (usually `192.168.1.1` or `192.168.0.1`)
   - Login with admin credentials

3. **Find DHCP Settings:**
   - Look for "DHCP Server", "LAN Setup", or "Address Reservation"
   - Different routers have different menu structures

4. **Add Reservation:**
   - Enter Pi's MAC address
   - Assign desired IP address (e.g., `192.168.1.100`)
   - Save settings

5. **Reboot Pi:**

```bash
sudo reboot
```

### Router-Specific Guides

<details>
<summary><b>Common Router Brands</b></summary>

**TP-Link:**
- Advanced → Network → DHCP Server → Address Reservation

**Netgear:**
- Advanced → Setup → LAN Setup → Address Reservation

**Asus:**
- LAN → DHCP Server → Manual Assignment

**Linksys:**
- Connectivity → Local Network → DHCP Reservations

**Ubiquiti UniFi:**
- Settings → Networks → Edit Network → DHCP → DHCP Range → Show Options → Add Static DHCP

**Google Nest WiFi:**
- Home app → Network → Advanced Networking → DHCP IP Reservations

</details>

## Method 4: NetworkManager CLI

For systems using NetworkManager.

### Step 1: Find Connection Name

```bash
nmcli connection show
```

### Step 2: Configure Static IP

Replace `"Wired connection 1"` with your actual connection name:

```bash
# Set static IP
sudo nmcli connection modify "Wired connection 1" \
  ipv4.addresses "192.168.1.100/24" \
  ipv4.gateway "192.168.1.1" \
  ipv4.dns "1.1.1.1,1.0.0.1" \
  ipv4.method manual

# Restart connection
sudo nmcli connection down "Wired connection 1"
sudo nmcli connection up "Wired connection 1"
```

## Verification

### Check Your New IP

```bash
# Method 1: Using ip command
ip addr show eth0

# Method 2: Using hostname command
hostname -I

# Method 3: Check specific interface
ip -4 addr show eth0 | grep inet
```

Expected output:
```
inet 192.168.1.100/24 brd 192.168.1.255 scope global eth0
```

### Test Connectivity

```bash
# Test gateway
ping -c 4 192.168.1.1

# Test internet
ping -c 4 1.1.1.1

# Test DNS resolution
ping -c 4 google.com
```

### Verify Pi-hole Still Works

```bash
# Check container status
docker ps
# or
podman ps

# Access web interface
curl -I http://localhost/admin/
```

## Choosing Your Static IP

### Best Practices

1. **Choose from DHCP Range End:**
   - Example: If DHCP is `192.168.1.100-200`, use `192.168.1.100` or `192.168.1.200`

2. **Outside DHCP Range (Recommended):**
   - Check router's DHCP range
   - Choose IP outside this range but within subnet
   - Example: If DHCP is `100-200`, use `50` or `250`

3. **Common Subnet Calculations:**

| Subnet | First IP | Last IP | Total IPs |
|--------|----------|---------|-----------|
| /24 | 192.168.1.1 | 192.168.1.254 | 254 |
| /23 | 192.168.0.1 | 192.168.1.254 | 510 |
| /22 | 192.168.0.1 | 192.168.3.254 | 1022 |

### Network Information You Need

Before setting static IP, gather this info:

| Information | How to Find | Example |
|-------------|-------------|---------|
| **Current IP** | `hostname -I` | 192.168.1.100 |
| **Gateway** | `ip route \| grep default` | 192.168.1.1 |
| **Subnet Mask** | Usually `/24` for home | /24 (255.255.255.0) |
| **DNS Servers** | Use `1.1.1.1` | 1.1.1.1, 1.0.0.1 |

## Common Network Configurations

### Standard Home Network (Most Common)

```bash
IP Address:  192.168.1.100/24
Gateway:     192.168.1.1
DNS:         1.1.1.1,1.0.0.1
```

### Alternative Network Range

```bash
IP Address:  192.168.0.100/24
Gateway:     192.168.0.1
DNS:         1.1.1.1,1.0.0.1
```

### 10.x Network

```bash
IP Address:  10.0.0.100/24
Gateway:     10.0.0.1
DNS:         1.1.1.1,1.0.0.1
```

## Troubleshooting

### Lost Network Connection

If you lose network access after setting static IP:

```bash
# Revert to DHCP immediately
sudo nmcli connection modify "Wired connection 1" ipv4.method auto
sudo nmcli connection down "Wired connection 1"
sudo nmcli connection up "Wired connection 1"

# Or edit dhcpcd.conf
sudo nano /etc/dhcpcd.conf
# Comment out or remove the static IP lines
sudo reboot
```

### Wrong Gateway/DNS

```bash
# Check what's actually configured
nmcli connection show "Wired connection 1" | grep ipv4

# Find correct gateway
ip route show default

# Test connectivity to gateway
ping -c 4 $(ip route show default | awk '{print $3}')
```

### Can't Access Internet After Static IP

```bash
# 1. Check if gateway is reachable
ping 192.168.1.1

# 2. Check DNS resolution
nslookup google.com

# 3. Check routing table
ip route

# 4. Restart networking
sudo systemctl restart NetworkManager
# or
sudo systemctl restart dhcpcd
```

### Static IP Not Persisting After Reboot

```bash
# Check if dhcpcd is enabled
sudo systemctl status dhcpcd

# Enable if needed
sudo systemctl enable dhcpcd

# Or check NetworkManager
sudo systemctl status NetworkManager
```

### Multiple Network Managers Conflict

```bash
# Check which network managers are running
systemctl status NetworkManager
systemctl status dhcpcd

# Disable one (keep NetworkManager on newer systems)
sudo systemctl disable dhcpcd
sudo systemctl stop dhcpcd
```

## After Setting Static IP

Once your static IP is configured:

1. Verify the IP is correct and persistent
2. Update Pi-hole configuration if IP changed:
   ```bash
   cd /opt/pihole-container
   sudo nano pihole.conf
   # Update SERVERIP
   sudo ./update.sh
   ```
3. Proceed to router configuration: [ROUTER_SETUP.md](ROUTER_SETUP.md)

## Additional Resources

- [Raspberry Pi Network Documentation](https://www.raspberrypi.org/documentation/configuration/tcpip/)
- [NetworkManager Documentation](https://networkmanager.dev/)
- [dhcpcd Documentation](https://roy.marples.name/projects/dhcpcd/)

---

**Next Step:** [Configure Your Router →](ROUTER_SETUP.md)

