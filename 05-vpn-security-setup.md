# VPN and Security Setup Guide

## Overview

This guide covers VPN setup for safe torrenting, security best practices, and how to properly configure network binding to prevent IP leaks. **Important:** VPNs often cause more problems than they solve, and for most users secure DNS is sufficient.

## When You Actually Need a VPN

**VPN is Recommended For:**
- Highly restrictive countries (China, Australia with heavy internet restrictions)
- ISPs that specifically throttle or block BitTorrent traffic
- Local laws that require VPN use for P2P activities
- Private tracker requirements

**VPN is NOT Needed For:**
- Usenet downloads (uses encrypted SSL connections)
- Most countries including the UK and US
- General internet privacy (use secure DNS instead)

**Key Point:** Only your torrent client should use VPN, never the *arr applications or Jellyfin.

Source: https://wiki.servarr.com/vpn

## Secure DNS Alternative (Recommended)

For most users, secure DNS fixes indexer connectivity issues without VPN complexity:

### DNS Server Configuration

**Standard Secure DNS Servers:**
- Cloudflare: `1.1.1.1` and `1.0.0.1`
- Google: `8.8.8.8` and `8.8.4.4`
- Quad9: `9.9.9.9` and `149.112.112.112`

**Windows DNS Setup:**
1. Open Network and Sharing Center
2. Change adapter settings
3. Right-click network connection → Properties
4. Select Internet Protocol Version 4 (TCP/IPv4) → Properties
5. Use the following DNS server addresses:
   - Preferred: `1.1.1.1`
   - Alternate: `1.0.0.1`

**Linux DNS Setup:**
```bash
# Using systemd-resolved (Ubuntu 18.04+)
sudo systemctl edit systemd-resolved
# Add:
[Service]
ExecStart=
ExecStart=/usr/lib/systemd/systemd-resolved --dns=1.1.1.1 --dns=1.0.0.1

sudo systemctl restart systemd-resolved

# Or edit /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
echo "nameserver 1.0.0.1" | sudo tee -a /etc/resolv.conf
```

**Router DNS Setup:**
- Configure DNS at router level for all devices
- Access router admin panel (usually 192.168.1.1)
- Set primary DNS to 1.1.1.1 and secondary to 1.0.0.1

Sources: 
- https://one.one.one.one/dns/
- https://developers.google.com/speed/public-dns

## VPN Setup (When Required)

### VPN Provider Requirements

**For BitTorrent, you MUST use a VPN with port forwarding:**

**Recommended Providers:**
- **TorGuard** - Excellent P2P support
- **Private Internet Access (PIA)** - Popular choice
- **Proton VPN** - Good privacy focus
- **AirVPN** - Technical users

**Avoid These Providers:**
- **Mullvad** - Removed port forwarding support
- **NordVPN** - No port forwarding
- **ExpressVPN** - No port forwarding
- **Most commercial VPNs** - Lack essential features

### TorGuard Setup Example

1. **Account Configuration**
   - Sign up at https://torguard.net/
   - Purchase streaming bundle for port forwarding
   - Request dedicated IP (optional but recommended)

2. **Port Forwarding Request**
   - Login to TorGuard client area
   - Request port forwarding
   - Note assigned port number

3. **Client Configuration**
   - Download OpenVPN config files
   - Import into VPN client
   - Connect to P2P-friendly servers

Source: https://trash-guides.info/Misc/How-to-setup-Torguard-for-port-forwarding/

## Binding qBittorrent to VPN

Critical security step: Bind torrent client to VPN interface to prevent IP leaks if VPN disconnects.

### Windows VPN Binding

1. **Identify VPN Network Adapter**
   - Open Start menu → type "view network connections"
   - Connect to VPN
   - Note the VPN adapter name (e.g., "TAP-NordVPN")

2. **Configure qBittorrent**
   - qBittorrent → Tools → Options → Advanced
   - Network Interface: Select VPN adapter name
   - Apply and restart qBittorrent

3. **Test IP Leak Protection**
   - Disconnect VPN
   - qBittorrent should stop all transfers
   - Reconnect VPN to resume

### Linux VPN Binding

1. **Identify VPN Interface**
   ```bash
   # Before connecting VPN
   ip route show
   
   # After connecting VPN (note new interface, usually tun0)
   ip route show
   ```

2. **Configure qBittorrent**
   ```bash
   # Edit qBittorrent config
   vim ~/.local/share/qBittorrent/config/qBittorrent.conf
   
   # Add or modify:
   [BitTorrent]
   Interface=tun0
   InterfaceAddress=
   ```

3. **Restart qBittorrent**
   ```bash
   systemctl --user restart qbittorrent-nox
   ```

### Verification

**Test VPN Binding:**
1. Start a download in qBittorrent
2. Disconnect VPN
3. Downloads should immediately stop
4. Reconnect VPN - downloads should resume

**IP Address Check:**
```bash
# Check your current IP
curl ifconfig.me

# Check qBittorrent's IP (should match VPN IP)
# Look at peer lists in qBittorrent to verify
```

Source: https://github.com/qbittorrent/qBittorrent/wiki/How-to-bind-your-vpn-to-prevent-ip-leaks.md

## Application-Specific VPN Configuration

### Only Torrent Client Uses VPN

**Correct Configuration:**
- qBittorrent: Bound to VPN interface
- Sonarr/Radarr/Lidarr: Direct internet access
- Jellyfin: Direct internet access
- Prowlarr: Direct internet access (or selective proxy)

**Why This Approach:**
- Prevents *arr apps from being blocked by image providers
- Avoids Cloudflare blocking issues
- Maintains metadata and update access
- Only P2P traffic goes through VPN

### Container-Based VPN (Advanced)

**Using Hotio qBittorrent with VPN:**
```yaml
# Docker Compose example
services:
  qbittorrent:
    image: hotio/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - VPN_ENABLED=true
      - VPN_PROVIDER=custom
      - VPN_CONFIG=/config/wireguard.conf
    volumes:
      - /data/config/qbittorrent:/config
      - /data/torrents:/data/torrents
    ports:
      - "8080:8080"
```

**Benefits:**
- Isolated VPN environment
- No impact on other applications
- Easy to manage and update

Source: https://hotio.dev/containers/qbittorrent/

## Security Best Practices

### Torrent Client Security

1. **Enable Encryption**
   - qBittorrent → Options → BitTorrent
   - Encryption mode: Require encryption
   - Helps avoid ISP deep packet inspection

2. **Disable DHT/PEX for Private Trackers**
   - Only for private tracker downloads
   - Prevents information leaks
   - Keep enabled for public trackers

3. **IP Filtering (Optional)**
   ```bash
   # Download IP filter lists
   wget https://www.iblocklist.com/lists.php
   # Import in qBittorrent → Options → Connection → IP Filtering
   ```

### Network Security

1. **Firewall Configuration**
   ```bash
   # Linux: Allow VPN traffic only
   sudo ufw --force reset
   sudo ufw default deny incoming
   sudo ufw default deny outgoing
   
   # Allow local network
   sudo ufw allow out on eth0 to 192.168.0.0/16
   sudo ufw allow in on eth0 from 192.168.0.0/16
   
   # Allow VPN interface
   sudo ufw allow out on tun0
   sudo ufw allow in on tun0
   
   # Allow essential services
   sudo ufw allow out 53 # DNS
   sudo ufw allow out 123 # NTP
   
   sudo ufw --force enable
   ```

2. **Kill Switch Configuration**
   - Many VPN clients provide kill switch
   - Blocks all internet if VPN disconnects
   - Configure as backup to interface binding

### Application Security

1. **Authentication**
   - Enable authentication for all web interfaces
   - Use strong, unique passwords
   - Consider reverse proxy with SSL

2. **Network Access**
   - Restrict access to local network only
   - Use firewall rules to block external access
   - Set up reverse proxy for secure remote access

3. **API Security**
   - Regenerate API keys regularly
   - Limit API access to necessary applications
   - Monitor API usage in logs

## Common VPN Problems and Solutions

### Issue: *Arr Apps Can't Connect

**Problem:** VPN blocks access to metadata providers, updates
**Solution:** 
- Don't run *arr apps through VPN
- Use split tunneling
- Configure selective proxy in Prowlarr only

### Issue: Slow Performance

**Problem:** VPN adds latency and reduces bandwidth
**Solution:**
- Choose geographically close VPN servers
- Use WireGuard protocol if available
- Test different server locations

### Issue: Private Tracker Bans

**Problem:** Many private trackers ban VPN usage
**Solution:**
- Check tracker rules before using VPN
- Use dedicated IP from VPN provider
- Consider if VPN is actually necessary

### Issue: Port Forwarding Not Working

**Problem:** Can't receive incoming connections
**Solution:**
```bash
# Test port forwarding
curl -s https://api.ipify.org && echo
nmap -p [your-forwarded-port] [your-vpn-ip]

# Configure qBittorrent
# Options → Connection → Listening Port: [forwarded-port]
```

## Monitoring and Maintenance

### VPN Connection Monitoring

**Linux Monitoring Script:**
```bash
#!/bin/bash
# /opt/scripts/vpn-monitor.sh

VPN_INTERFACE="tun0"
SERVICE="qbittorrent-nox"

if ! ip link show $VPN_INTERFACE &> /dev/null; then
    echo "VPN down, stopping torrent client"
    systemctl stop $SERVICE
else
    if ! systemctl is-active --quiet $SERVICE; then
        echo "VPN up, starting torrent client"
        systemctl start $SERVICE
    fi
fi
```

### Log Monitoring

**Key Logs to Monitor:**
- VPN client logs for connection issues
- qBittorrent logs for binding failures
- Firewall logs for blocked connections

**Example Log Analysis:**
```bash
# Monitor VPN status
journalctl -u openvpn@client -f

# Check qBittorrent binding
grep "Interface" ~/.local/share/qBittorrent/config/qBittorrent.conf

# Monitor torrent activity
netstat -i # Check interface traffic
```

### Regular Security Audits

1. **IP Leak Tests**
   - Use online IP leak test tools
   - Verify torrent IP matches VPN IP
   - Test with VPN disconnection

2. **Connection Verification**
   ```bash
   # Check what IP torrents are using
   ss -tuln | grep :8999 # Your torrent port
   
   # Verify VPN routing
   traceroute 8.8.8.8
   ```

3. **Performance Monitoring**
   - Monitor download speeds with/without VPN
   - Check connection success rates
   - Verify port forwarding functionality

## Conclusion

**For Most Users:**
- Use secure DNS servers (1.1.1.1, 8.8.8.8)
- Skip VPN unless legally required
- Focus on proper application configuration

**If VPN Required:**
- Choose provider with port forwarding
- Bind only torrent client to VPN
- Keep other applications on direct internet
- Monitor for leaks and performance issues

**Next Guide:** [Docker Deployment (Optional)](./06-docker-deployment.md)

For users who prefer containerized deployment of the entire media stack.