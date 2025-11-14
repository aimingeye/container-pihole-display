# Pi-hole Container for Raspberry Pi

<p align="center">
  <img src="https://pi-hole.github.io/graphics/Vortex/Vortex_with_text.png" width="150" height="260" alt="Pi-hole">
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell-Script-4EAA25?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-Compatible-C51A4A?logo=raspberry-pi)](https://www.raspberrypi.org/)

**One-command installation of Pi-hole on Raspberry Pi using containers.**  
Optimized for Pi Zero 2W and all Raspberry Pi models.

## Why This Installer?

- **Single Command Setup** - One script does everything
- **Smart Auto-Detection** - Minimal user input required
- **Pi Zero 2W Optimized** - Special optimizations for low-memory devices
- **Optional Display Support** - E-ink display integration built-in
- **Production Ready** - Clean, well-tested, documented code
- **Easy Updates** - Simple update and uninstall scripts included

## Quick Start

### One-Line Installation

```bash
curl -sSL https://raw.githubusercontent.com/aimingeye/container-pihole-display/main/install.sh | sudo bash
```

### Or Clone and Install

```bash
git clone https://github.com/aimingeye/container-pihole-display.git
cd container-pihole-display
sudo ./install.sh
```

That's it! The installer will:
1. Detect your Pi model and optimize accordingly
2. Auto-detect network interface and IP address
3. Install Podman (lightweight container engine)
4. Configure and start Pi-hole
5. Set up auto-start on boot

## Features

### Core Features

- **Universal Pi Support** - Pi Zero, Zero W, Zero 2W, Pi 1-5
- **Smart Detection** - Auto-detects everything possible
- **Container-Based** - Uses Podman (lightweight) or Docker
- **Systemd Integration** - Starts automatically on boot
- **Low Resource Usage** - Optimized for Pi Zero 2W (~120MB RAM)
- **Complete** - Includes update and uninstall scripts

### Advanced Features

- **CLI Flags** - Non-interactive mode for automation
- **E-ink Display Support** - Optional real-time stats display
- **Multiple DNS Providers** - Cloudflare, Google, Quad9, OpenDNS
- **Swap Management** - Auto-creates swap on low-memory devices
- **Backup System** - Automatic backups on updates

## Requirements

- Raspberry Pi (any model, Pi Zero 2W recommended)
- Raspberry Pi OS (Buster, Bullseye, or Bookworm)
- Internet connection
- Root/sudo access

## Installation Options

### Interactive Installation (Recommended)

```bash
sudo ./install.sh
```

The installer will ask you:
- Timezone selection
- Web password (or auto-generate)
- DNS provider preference
- Optional display support

### Quick Install (Auto-Confirm)

```bash
sudo ./install.sh -y
```

Uses sensible defaults, only asks critical questions.

### Non-Interactive Installation

```bash
sudo ./install.sh -n \
  --password "mySecurePass123" \
  --timezone "America/New_York" \
  --dns-provider 1
```

Perfect for automation or scripting.

### Install with E-ink Display

```bash
sudo ./install.sh --display --display-type 2.13
```

Supports Waveshare 2.13", 2.7", and 4.2" e-ink displays.

### CLI Options

```
Options:
  -h, --help              Show help message
  -v, --version           Show version
  -y, --yes               Auto-confirm all prompts
  -n, --non-interactive   Non-interactive mode
  --display               Install e-ink display support
  --display-type TYPE     Display type (2.13, 2.7, 4.2)
  --timezone TZ           Set timezone
  --password PASS         Set web password
  --dns-provider NUM      DNS provider (1-4)
  --skip-wifi             Skip WiFi configuration
  --ip ADDRESS            Set static IP
  --interface IFACE       Network interface

Examples:
  sudo ./install.sh
  sudo ./install.sh -y --display
  sudo ./install.sh -n --password abc123 --timezone America/Chicago
```

## After Installation

### Access Pi-hole

Open your browser to:
```
http://YOUR_PI_IP/admin
```

Your password is displayed at the end of installation and saved in:
```
/opt/pihole-container/pihole.conf
```

### Configure Static IP

**Important:** Set a static IP so Pi-hole always has the same address.

See [STATIC_IP.md](STATIC_IP.md) for detailed instructions.

Quick method:
```bash
sudo nmtui
# Select "Edit a connection" → Manual IPv4 → Set your IP
```

### Configure Your Router

To use Pi-hole network-wide, set your router's DNS to your Pi's IP.

See [ROUTER_SETUP.md](ROUTER_SETUP.md) for detailed router-specific guides.

Quick summary:
1. Login to router admin panel
2. Find DHCP/DNS settings
3. Set Primary DNS to your Pi's IP
4. Set Secondary DNS to 1.1.1.1 (backup)
5. Save and reboot router

## Management

### Status and Logs

```bash
# Check status
podman ps
# or
docker ps

# View logs
podman logs pihole
# or
docker logs pihole

# Check service
systemctl status pihole-container
```

### Update Pi-hole

```bash
sudo ./update.sh
```

Automatically:
- Creates backup
- Pulls latest Pi-hole image
- Restarts container
- Preserves all settings

### Restart Pi-hole

```bash
# Via systemd
sudo systemctl restart pihole-container

# Or manually
cd /opt/pihole-container
sudo podman-compose restart
```

### Stop/Start

```bash
sudo systemctl stop pihole-container
sudo systemctl start pihole-container
```

### Uninstall

```bash
sudo ./uninstall.sh
```

You'll be asked whether to:
- Remove Pi-hole data (settings, blocklists)
- Remove container engine (Podman/Docker)

## Performance

### Resource Usage by Pi Model

| Model | RAM Usage | CPU (Idle) | Recommended |
|-------|-----------|------------|-------------|
| Pi Zero W | ~130MB | 10-15% | Yes (slow) |
| **Pi Zero 2W** | **~120MB** | **5-8%** | **Best for Zero** |
| Pi 3 | ~100MB | 2-5% | Excellent |
| Pi 4 | ~90MB | 1-3% | Excellent |
| Pi 5 | ~85MB | 1-2% | Excellent |

### Optimizations Applied

The installer automatically applies optimizations based on your Pi model:

**All Models:**
- Podman instead of Docker (lower overhead)
- Single-threaded image pulls
- Optimized storage overlay
- Systemd cgroup management

**Pi Zero/Zero 2W/Pi 1:**
- Additional memory optimizations
- 512MB swap file creation
- Limited parallel operations
- Reduced buffer sizes

## File Structure

```
/opt/pihole-container/          # Installation directory
├── docker-compose.yml          # Container configuration
├── pihole.conf                 # Your settings & password
└── backups/                    # Automatic backups (on update)

/opt/pihole-data/               # Pi-hole data (persists across updates)
├── etc-pihole/                 # Pi-hole config & database
│   ├── gravity.db              # Blocklist database
│   └── pihole-FTL.conf         # FTL configuration
└── etc-dnsmasq.d/              # DNS configuration

/etc/systemd/system/
├── pihole-container.service    # Pi-hole service
└── pihole-display.service      # Display service (if installed)
```

## E-ink Display Support

### Setup Display

During installation:
```bash
sudo ./install.sh --display --display-type 2.13
```

Or add later:
```bash
sudo ./install.sh --display --display-type 2.13
```

### Supported Displays

- Waveshare 2.13" (250x122)
- Waveshare 2.7" (264x176)
- Waveshare 4.2" (400x300)
- Other displays (manual configuration)

### Display Commands

```bash
# Start display
sudo systemctl start pihole-display

# Stop display
sudo systemctl stop pihole-display

# View logs
sudo journalctl -u pihole-display -f

# Enable auto-start
sudo systemctl enable pihole-display
```

### What's Displayed

- Current time
- Total queries today
- Blocked queries
- Block percentage (with progress bar)
- Blocklist size
- Updates every 10 minutes

## Troubleshooting

### Pi-hole not accessible

```bash
# Check if container is running
podman ps

# Check logs for errors
podman logs pihole

# Restart container
cd /opt/pihole-container
sudo podman-compose restart
```

### Port conflicts

If ports 53 or 80 are in use:

```bash
# Check what's using ports
sudo lsof -i :53
sudo lsof -i :80

# Common fix: disable systemd-resolved
sudo systemctl disable --now systemd-resolved
```

### DNS not working

1. Verify Pi-hole is running: `podman ps`
2. Check your device's DNS points to Pi-hole IP
3. Test DNS: `nslookup google.com YOUR_PI_IP`
4. Check router DHCP/DNS settings

### Performance issues on Pi Zero

```bash
# Check memory
free -h

# Check if swap is active
swapon --show

# Restart to free memory
sudo systemctl restart pihole-container
```

### Installation fails

```bash
# Check system logs
sudo journalctl -xe

# Verify internet connection
ping 1.1.1.1

# Try manual Podman install
sudo apt update
sudo apt install podman
```

## DNS Providers

Choose during installation or use `--dns-provider` flag:

| Provider | Primary | Secondary | Privacy | Speed |
|----------|---------|-----------|---------|-------|
| **Cloudflare** | 1.1.1.1 | 1.0.0.1 | Excellent | Excellent |
| **Google** | 8.8.8.8 | 8.8.4.4 | Good | Excellent |
| **Quad9** | 9.9.9.9 | 149.112.112.112 | Excellent | Very Good |
| **OpenDNS** | 208.67.222.222 | 208.67.220.220 | Very Good | Very Good |

Default: Cloudflare (fastest, privacy-focused)

## Advanced Configuration

### Custom DNS Servers

```bash
sudo ./install.sh --dns-provider 5
# Then enter your custom DNS servers
```

### Change Settings After Install

Edit the configuration:
```bash
sudo nano /opt/pihole-container/docker-compose.yml
```

Apply changes:
```bash
cd /opt/pihole-container
sudo podman-compose down
sudo podman-compose up -d
```

### Static IP Configuration

Best practice: Configure static IP before setting up router DNS.

See [STATIC_IP.md](STATIC_IP.md) for multiple methods:
- nmtui (easiest)
- dhcpcd (traditional)
- Router DHCP reservation
- NetworkManager CLI

### Router Configuration

See [ROUTER_SETUP.md](ROUTER_SETUP.md) for guides on:
- TP-Link
- Netgear
- Asus
- Linksys
- Ubiquiti UniFi
- Google Nest WiFi
- Synology
- pfSense/OPNsense
- And many more...

## Security Best Practices

1. **Strong Password** - Use `--password` with a strong password
2. **Static IP** - Configure static IP (see STATIC_IP.md)
3. **Router Security** - Secure your router admin access
4. **Regular Updates** - Run `sudo ./update.sh` monthly
5. **Firewall** - Consider setting up UFW
6. **Local Network Only** - Pi-hole only accessible on local network by default

## Why Podman?

This installer uses Podman by default (auto-installs if no container engine found):

**Advantages:**
- **Lightweight** - Lower memory footprint than Docker
- **Daemonless** - No background daemon consuming resources
- **Faster** - Better performance on low-resource Pis
- **Rootless** - Better security model
- **Compatible** - Drop-in Docker replacement

**Docker Support:**
If Docker is already installed, the installer will use it instead.

## Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Open a Pull Request

### Development

Test on a fresh Pi OS installation:
```bash
git clone https://github.com/aimingeye/pi-hole-container.git
cd pi-hole-container
sudo ./install.sh -y
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Pi-hole](https://pi-hole.net/) - Network-wide ad blocking
- [Podman](https://podman.io/) - Container engine
- [Docker](https://www.docker.com/) - Container platform
- Raspberry Pi community

## Support

- **Issues:** [GitHub Issues](https://github.com/aimingeye/container-pihole-display/issues)
- **Discussions:** [GitHub Discussions](https://github.com/aimingeye/container-pihole-display/discussions)
- **Pi-hole Docs:** [Official Documentation](https://docs.pi-hole.net/)

## FAQ

**Q: Which Pi model should I use?**  
A: Pi Zero 2W offers the best value. Pi 3/4/5 for best performance.

**Q: How much does Pi-hole slow down my Pi Zero 2W?**  
A: Minimal impact. ~120MB RAM, 5-8% CPU idle. Works great!

**Q: Can I use Docker instead of Podman?**  
A: Yes! If Docker is already installed, the installer will use it.

**Q: How do I change the web password?**  
A: Edit `/opt/pihole-container/docker-compose.yml`, change `WEBPASSWORD`, then restart.

**Q: Will this work on Pi OS Lite?**  
A: Yes! Actually recommended for headless setups.

**Q: Can I run other containers alongside Pi-hole?**  
A: Yes! Podman/Docker can run multiple containers.

**Q: How do I backup my Pi-hole?**  
A: Data is in `/opt/pihole-data`. Backup that directory. Updates auto-backup to `/opt/pihole-container/backups/`.

**Q: Does this work with IPv6?**  
A: IPv6 is disabled by default for better compatibility. Can be enabled manually.

**Q: What if my router doesn't allow custom DNS?**  
A: Configure DNS on each device individually. See ROUTER_SETUP.md for details.

---

**Made for the Raspberry Pi and Pi-hole communities**  
**Tested on Pi Zero 2W, Pi 3, Pi 4, Pi 5**
