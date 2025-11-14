# Router DNS Configuration Guide

This guide will help you configure your router to use Pi-hole as your network-wide DNS server, blocking ads and trackers for all devices automatically.

## Table of Contents

- [Overview](#overview)
- [Before You Begin](#before-you-begin)
- [General Configuration Steps](#general-configuration-steps)
- [Router-Specific Guides](#router-specific-guides)
- [Testing Your Configuration](#testing-your-configuration)
- [Troubleshooting](#troubleshooting)
- [Alternative: Per-Device Configuration](#alternative-per-device-configuration)

## Overview

### What This Does

When you configure your router to use Pi-hole as DNS:
- All devices on your network automatically use Pi-hole
- No need to configure each device individually
- Works for phones, tablets, smart TVs, IoT devices, etc.
- Ads are blocked network-wide

### What You Need

- Pi-hole installed and running
- Static IP configured for your Pi (see [STATIC_IP.md](STATIC_IP.md))
- Router admin access (username/password)
- 5-10 minutes

## Before You Begin

### 1. Verify Pi-hole is Working

```bash
# SSH into your Pi and check status
docker ps
# or
podman ps

# You should see the pihole container running
```

### 2. Note Your Pi's IP Address

```bash
hostname -I
# Example output: 192.168.1.100
```

### 3. Test Pi-hole DNS Locally

From your Pi:
```bash
# Test DNS resolution through Pi-hole
nslookup google.com 127.0.0.1

# Should return an IP address
```

### 4. Find Your Router's IP

Usually one of these:
- `192.168.1.1`
- `192.168.0.1`
- `192.168.1.254`
- `10.0.0.1`

Check with:
```bash
ip route | grep default
```

## General Configuration Steps

These steps apply to most routers. Specific router guides are below.

### Step 1: Access Router Admin Panel

1. Open a web browser
2. Navigate to your router's IP address (e.g., `http://192.168.1.1`)
3. Log in with admin credentials

**Default credentials** (if you haven't changed them):
- Check the sticker on your router
- Common defaults:
  - Username: `admin` | Password: `admin`
  - Username: `admin` | Password: `password`
  - Username: `admin` | Password: (blank)

### Step 2: Find DNS Settings

Look for these menu items (varies by router):
- **DHCP Settings**
- **LAN Settings**
- **DNS Settings**
- **Internet Setup**
- **WAN Settings**
- **Advanced Settings**

### Step 3: Configure DNS Servers

**Primary DNS Server:** `192.168.1.100` (Your Pi-hole IP)
**Secondary DNS Server:** `1.1.1.1` (Backup - Cloudflare)

**Important Notes:**
- Some devices may use the secondary DNS if primary is slow
- For maximum ad-blocking, you can set secondary to your Pi-hole IP as well
- Or leave secondary as a public DNS for redundancy

### Step 4: Save and Reboot

1. Click **Save** or **Apply**
2. Reboot your router (some routers do this automatically)
3. Wait 2-3 minutes for router to restart

### Step 5: Renew DHCP Leases on Devices

For devices to use the new DNS:

**Windows:**
```cmd
ipconfig /release
ipconfig /renew
```

**Mac/Linux:**
```bash
sudo dhclient -r
sudo dhclient
```

**Mobile Devices:**
- Turn Wi-Fi off and on
- Or reboot the device

## Router-Specific Guides

### TP-Link Routers

#### Consumer Models (Archer, etc.)

1. Navigate to `http://192.168.0.1` or `http://192.168.1.1`
2. Login (default: admin/admin)
3. Go to **Advanced** → **Network** → **DHCP Server**
4. Set **Primary DNS:** `192.168.1.100`
5. Set **Secondary DNS:** `1.1.1.1`
6. Click **Save**
7. Reboot router: **System Tools** → **Reboot**

#### Omada/Business

1. Navigate to controller or `https://192.168.0.1`
2. Go to **Settings** → **Networks** → Select your network
3. Scroll to **DHCP Server** section
4. Enable **Manual DNS**
5. Set **DNS Server 1:** `192.168.1.100`
6. Set **DNS Server 2:** `1.1.1.1`
7. Click **Apply**

### Netgear Routers

1. Navigate to `http://www.routerlogin.net` or `http://192.168.1.1`
2. Login (default: admin/password)
3. Go to **Advanced** → **Setup** → **Internet Setup**
4. Uncheck **Use these DNS servers automatically**
5. Set **Primary DNS:** `192.168.1.100`
6. Set **Secondary DNS:** `1.1.1.1`
7. Click **Apply**

### Asus Routers

1. Navigate to `http://router.asus.com` or `http://192.168.1.1`
2. Login
3. Go to **LAN** → **DHCP Server** tab
4. Under **DNS and WINS Server Setting**
5. Set **DNS Server 1:** `192.168.1.100`
6. Set **DNS Server 2:** `1.1.1.1`
7. Click **Apply**

### Linksys Routers

#### Older Models

1. Navigate to `http://192.168.1.1`
2. Login (default: admin/admin)
3. Go to **Setup** → **Basic Setup**
4. Under **Network Setup** → **DHCP Server Setting**
5. Set **Static DNS 1:** `192.168.1.100`
6. Set **Static DNS 2:** `1.1.1.1`
7. Click **Save Settings**

#### Smart Wi-Fi (Newer Models)

1. Navigate to `http://myrouter.local` or use Linksys app
2. Login
3. Go to **Connectivity** → **Local Network** → **DHCP Server**
4. Set **DNS Server 1:** `192.168.1.100`
5. Set **DNS Server 2:** `1.1.1.1`
6. Click **OK**

### Google Nest WiFi / Google WiFi

**Note:** Google WiFi doesn't allow custom DNS via the router. Use per-device configuration or use the Google Home app to set DNS for the entire network.

#### Using Google Home App

1. Open **Google Home** app
2. Tap **Wi-Fi** → **Settings** (gear icon)
3. Tap **Advanced networking** → **DNS**
4. Choose **Custom**
5. Set **Primary DNS:** `192.168.1.100`
6. Set **Secondary DNS:** `1.1.1.1`
7. Tap **Save**

### Ubiquiti UniFi

1. Open **UniFi Controller** (web or mobile app)
2. Go to **Settings** → **Networks**
3. Select your network (usually **Default** or **LAN**)
4. Scroll to **DHCP**
5. Set **DHCP DNS Server:** `Manual`
6. Set **DNS Server 1:** `192.168.1.100`
7. Set **DNS Server 2:** `1.1.1.1`
8. Click **Apply Changes**

### Netgear Orbi

1. Navigate to `http://orbilogin.com` or `http://192.168.1.1`
2. Login
3. Go to **Advanced** → **Setup** → **Internet Setup**
4. Uncheck **Get automatically from ISP**
5. Set **Primary DNS:** `192.168.1.100`
6. Set **Secondary DNS:** `1.1.1.1`
7. Click **Apply**

### Eero

Eero doesn't allow custom DNS through the app. Options:

1. **Use Pi-hole DHCP** (advanced - disables router DHCP)
2. **Configure per-device** (see below)
3. **Use Eero Plus with ad blocking** (paid feature, but less powerful than Pi-hole)

### AT&T Gateway/Modem

1. Navigate to `http://192.168.1.254`
2. Login
3. Go to **Settings** → **LAN** → **DHCP**
4. Set **Primary DNS:** `192.168.1.100`
5. Set **Secondary DNS:** `1.1.1.1`
6. Click **Save**

### Xfinity xFi Gateway

Xfinity gateways have limited DNS customization. Best options:

1. **Set Gateway to Bridge Mode** + Use your own router
2. **Configure per-device DNS**

#### Bridge Mode (Recommended)

1. Login to `http://10.0.0.1`
2. Go to **Gateway** → **At a Glance**
3. Click **Bridge Mode** → **Enable**
4. Connect your own router
5. Configure DNS on your router

### Verizon Fios Router

1. Navigate to `http://192.168.1.1`
2. Login
3. Go to **My Network** → **Network Connections** → **Broadband Connection (Ethernet/Coax)**
4. Click **Settings**
5. Click **DNS Server** tab
6. Select **Use these DNS servers**
7. Set **Primary DNS:** `192.168.1.100`
8. Set **Secondary DNS:** `1.1.1.1`
9. Click **Apply**

### Synology Router (RT2600ac, MR2200ac)

1. Open **Synology Router Manager** (SRM)
2. Go to **Network Center** → **Local Network** → **DHCP Server**
3. Under **DNS Server**, select **Manual**
4. Set **Primary DNS:** `192.168.1.100`
5. Set **Secondary DNS:** `1.1.1.1`
6. Click **Apply**

### MikroTik RouterOS

```bash
# Via CLI or Terminal
/ip dhcp-server network
set 0 dns-server=192.168.1.100,1.1.1.1

# Via WebFig/WinBox
# IP → DHCP Server → Networks
# Set DNS Servers: 192.168.1.100,1.1.1.1
```

### OpenWrt / DD-WRT

#### OpenWrt

1. Navigate to LuCI web interface
2. Go to **Network** → **Interfaces** → **LAN** → **Edit**
3. Go to **DHCP Server** → **Advanced Settings**
4. Set **DHCP-Options:** `6,192.168.1.100,1.1.1.1`
5. Click **Save & Apply**

#### DD-WRT

1. Navigate to web interface
2. Go to **Setup** → **Basic Setup**
3. Under **Network Address Server Settings (DHCP)**
4. Set **Static DNS 1:** `192.168.1.100`
5. Set **Static DNS 2:** `1.1.1.1`
6. Set **Use DNSMasq for DNS:** `Enable`
7. Click **Save** → **Apply Settings**

### pfSense / OPNsense

#### pfSense

1. Navigate to web interface
2. Go to **Services** → **DHCP Server** → **LAN**
3. Scroll to **Servers**
4. Add DNS servers:
   - `192.168.1.100`
   - `1.1.1.1`
5. Click **Save**

#### OPNsense

1. Navigate to web interface
2. Go to **Services** → **DHCPv4** → **[LAN]**
3. Set **DNS servers:** `192.168.1.100,1.1.1.1`
4. Click **Save**

## Testing Your Configuration

### Method 1: Check Device DNS Settings

**Windows:**
```cmd
ipconfig /all
```
Look for "DNS Servers" - should show your Pi-hole IP

**Mac:**
```bash
scutil --dns | grep 'nameserver\[0\]'
```

**Linux:**
```bash
cat /etc/resolv.conf
```

### Method 2: Test DNS Resolution

**From any device:**
```bash
nslookup flurry.com
# Should return 0.0.0.0 or Pi-hole IP (blocked)

nslookup google.com
# Should return normal IP address
```

**Using online tools:**
- Visit: https://dnsleaktest.com
- Should show your Pi-hole IP as the DNS server

### Method 3: Check Pi-hole Dashboard

1. Navigate to `http://YOUR_PI_IP/admin`
2. Login
3. Look at the **Dashboard**:
   - **Queries** should be increasing
   - **Queries blocked** should show blocked ads
4. Go to **Tools** → **Network** to see connected devices

### Method 4: Visual Test

Visit an ad-heavy website:
- https://www.speedtest.net
- https://www.forbes.com
- Any news website

Ads should be blocked/missing!

## Troubleshooting

### Issue: Devices Still Showing Ads

**Possible Causes:**

1. **Devices haven't renewed DHCP:**
   - Restart devices or disconnect/reconnect to Wi-Fi
   - Force DHCP renewal (see commands above)

2. **Device has manual DNS set:**
   - Check device network settings
   - Remove any custom DNS servers

3. **App using hard-coded DNS:**
   - Some apps bypass system DNS
   - Solution: Enable DNS rebinding protection in Pi-hole

4. **Cached DNS entries:**
   - Clear browser cache
   - Flush DNS cache on device

### Issue: Internet Not Working

**Possible Causes:**

1. **Pi-hole is down:**
   ```bash
   docker ps  # Check if container is running
   ```

2. **Wrong IP address in router:**
   - Double-check Pi-hole IP in router settings
   - Verify Pi-hole IP hasn't changed

3. **No upstream DNS configured:**
   - Pi-hole needs upstream DNS to resolve queries
   - Check Pi-hole Settings → DNS

**Quick Fix:**
```bash
# SSH to Pi
cd /opt/pihole-container
docker-compose restart
# or
podman-compose restart
```

### Issue: Slow Internet

**Possible Causes:**

1. **Pi Zero performance:**
   - Pi Zero may struggle with high query volume
   - Consider upgrading to Pi 3 or 4

2. **Slow upstream DNS:**
   - Try different upstream DNS providers
   - Pi-hole Settings → DNS → Select faster DNS

3. **Large blocklists:**
   - Too many blocklists can slow queries
   - Reduce to essential lists

### Issue: Can't Access Router Settings After Configuration

If you locked yourself out:

**Solution 1: Reset DNS temporarily**
```bash
# On your computer, set DNS manually to 1.1.1.1
```

**Solution 2: Connect directly to router**
```bash
# Use ethernet cable directly to router
# Bypass DNS issues
```

**Solution 3: Router factory reset**
- Last resort: hold reset button on router for 10+ seconds

### Issue: Some Devices Work, Others Don't

**Possible Causes:**

1. **Static DNS on some devices:**
   - Check network settings on non-working devices
   - Remove custom DNS

2. **VPN on devices:**
   - VPNs often set their own DNS
   - Configure VPN to use Pi-hole or disable VPN

3. **Guest network:**
   - Guest networks may have separate DHCP
   - Configure DNS for guest network too

## Alternative: Per-Device Configuration

If you can't change router DNS, configure each device individually:

### Windows

1. **Settings** → **Network & Internet** → **Ethernet/Wi-Fi** → **Change adapter options**
2. Right-click connection → **Properties**
3. Select **Internet Protocol Version 4 (TCP/IPv4)** → **Properties**
4. Select **Use the following DNS server addresses**
5. Preferred DNS: `192.168.1.100`
6. Alternate DNS: `1.1.1.1`
7. Click **OK**

### macOS

1. **System Preferences** → **Network**
2. Select your connection → **Advanced**
3. Go to **DNS** tab
4. Click **+** and add: `192.168.1.100`
5. Add another: `1.1.1.1`
6. Click **OK** → **Apply**

### iOS

1. **Settings** → **Wi-Fi**
2. Tap **(i)** next to your network
3. Scroll to **DNS** → **Configure DNS** → **Manual**
4. Remove existing servers
5. Add Server: `192.168.1.100`
6. Add Server: `1.1.1.1`
7. Tap **Save**

### Android

1. **Settings** → **Network & Internet** → **Wi-Fi**
2. Tap and hold your network → **Modify network**
3. Tap **Advanced options**
4. Change **IP settings** to **Static**
5. Set **DNS 1:** `192.168.1.100`
6. Set **DNS 2:** `1.1.1.1`
7. Keep other settings as they were
8. Tap **Save**

### Linux

#### Using NetworkManager (GUI)
1. Click network icon → **Edit Connections**
2. Select connection → **Edit** → **IPv4 Settings**
3. Change **Method** to **Automatic (DHCP) addresses only**
4. Set **DNS servers:** `192.168.1.100,1.1.1.1`
5. Click **Save**

#### Using netplan (Ubuntu Server)
```bash
sudo nano /etc/netplan/01-netcfg.yaml
```

Add:
```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      nameservers:
        addresses: [192.168.1.100, 1.1.1.1]
```

Apply:
```bash
sudo netplan apply
```

## Best Practices

1. **Always set a secondary DNS:** Use a public DNS (1.1.1.1 or 8.8.8.8) as backup
2. **Monitor Pi-hole:** Check dashboard regularly for issues
3. **Keep Pi-hole updated:** Run `./update.sh` monthly
4. **Document your settings:** Take screenshots of router config
5. **Whitelist as needed:** Some sites may break - whitelist them in Pi-hole
6. **Test before committing:** Try on one device first

## Additional Resources

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole Discourse](https://discourse.pi-hole.net/)
- Your router's manual
- [DNS Leak Test](https://dnsleaktest.com)

---

**Previous Step:** [Configure Static IP](STATIC_IP.md)

**Next Step:** Enjoy ad-free internet on all your devices!

