# Indexers and Trackers Setup Guide

## Overview

Indexers are services that search torrent sites and provide results to your automation tools. This guide covers setting up Prowlarr (recommended) or Jackett for managing indexers and connecting them to Sonarr, Radarr, and Lidarr.

## Prowlarr Setup (Recommended)

Prowlarr is the modern indexer manager that integrates seamlessly with all *arr applications, eliminating the need to configure indexers separately in each app.

### Installation

**Windows:**
1. Download from https://prowlarr.com/
2. Install with default settings
3. Access at `http://localhost:9696`

**Linux:**
```bash
# Download and install
curl -L -O https://github.com/Prowlarr/Prowlarr/releases/latest/download/Prowlarr.master.$(uname -m).linux.tar.gz
sudo tar -xzf Prowlarr.*.tar.gz -C /opt/
sudo chown -R prowlarr:prowlarr /opt/Prowlarr

# Create service user
sudo useradd -d /var/lib/prowlarr -s /bin/bash prowlarr
sudo mkdir -p /var/lib/prowlarr
sudo chown prowlarr:prowlarr /var/lib/prowlarr

# Create systemd service
sudo tee /etc/systemd/system/prowlarr.service > /dev/null <<EOF
[Unit]
Description=Prowlarr Daemon
After=syslog.target network.target

[Service]
User=prowlarr
Group=prowlarr
Type=simple
ExecStart=/opt/Prowlarr/Prowlarr -nobrowser -data=/var/lib/prowlarr
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable prowlarr
sudo systemctl start prowlarr
```

### Initial Configuration

1. **Applications Setup**
   - Settings → Apps
   - Add Sonarr:
     - Sync Level: Full Sync
     - Server: http://localhost:8989
     - API Key: (from Sonarr Settings → General)
   - Add Radarr:
     - Server: http://localhost:7878
     - API Key: (from Radarr Settings → General)
   - Add Lidarr:
     - Server: http://localhost:8686
     - API Key: (from Lidarr Settings → General)

2. **Download Clients**
   - Settings → Download Clients
   - Add qBittorrent:
     - Host: localhost
     - Port: 8080
     - Username/Password: (your qBittorrent credentials)

### Adding Indexers

**Public Indexers:**
1. **Indexers → Add Indexer**
   - Popular public trackers:
     - The Pirate Bay
     - RARBG (if available)
     - 1337x
     - EZTV (TV shows)
     - YTS (movies)

2. **Configuration per Indexer**
   - Categories: Select relevant categories (Movies, TV, Audio)
   - Priority: Set based on quality preference
   - Enable RSS: Yes for automatic checking
   - Enable Automatic Search: Yes
   - Enable Interactive Search: Yes

**Semi-Private/Private Indexers:**
- Requires accounts and API keys
- Examples: IPTorrents, TorrentLeech, AlphaRatio
- Configuration varies per tracker
- Check tracker-specific requirements

**Usenet Indexers (Optional):**
- Add if you have Usenet access
- Popular options: NZBGeek, DrunkenSlug, NZB.su
- Requires separate Usenet client (SABnzbd, NZBGet)

### Testing Configuration

1. **Test Indexers**
   - Indexers → Test all indexers
   - Verify green checkmarks
   - Fix any connection issues

2. **Test Application Sync**
   - Settings → Apps → Test connections
   - Verify indexers sync to all applications

Source: https://wiki.servarr.com/prowlarr

## Jackett Setup (Alternative)

Use Jackett if you prefer individual indexer management or need specific indexers not available in Prowlarr.

### Installation

**Windows:**
1. Download installer from https://github.com/Jackett/Jackett/releases
2. Install with "Install as Windows Service" option
3. Access at `http://localhost:9117`

**Linux:**
```bash
# Download and install
cd /opt
sudo wget -Nc https://github.com/Jackett/Jackett/releases/latest/download/Jackett.Binaries.LinuxAMDx64.tar.gz
sudo tar -xzf Jackett.Binaries.LinuxAMDx64.tar.gz
sudo rm Jackett.Binaries.LinuxAMDx64.tar.gz
cd Jackett*
sudo chown $(whoami):$(id -g) -R "/opt/Jackett"

# Install as service
sudo ./install_service_systemd.sh
sudo systemctl start jackett.service
```

### Configuration

1. **Add Indexers**
   - Browse available indexers
   - Add popular public trackers
   - Configure private trackers with credentials

2. **FlareSolverr (Optional)**
   - Required for Cloudflare-protected sites
   - Install FlareSolverr: https://github.com/FlareSolverr/FlareSolverr
   - Configure in Jackett settings

3. **Copy Torznab URLs**
   - Each indexer provides a Torznab URL
   - Copy these for use in *arr applications

### Adding Jackett Indexers to *arr Applications

**In Sonarr/Radarr/Lidarr:**

1. **Settings → Indexers → Add Indexer**
2. **Select Torznab**
3. **Configuration:**
   - Name: Indexer name from Jackett
   - URL: Torznab URL from Jackett
   - API Key: Jackett API key
   - Categories: Appropriate categories (5000 for TV, 2000 for movies, 3000 for music)

4. **Test and Save**

Source: https://github.com/Jackett/Jackett

## Indexer Categories

Understanding category numbers is crucial for proper setup:

**Standard Categories:**
- **Movies:** 2000-2999
  - 2030: Movies/DVD
  - 2040: Movies/HD
  - 2050: Movies/UHD
- **TV Shows:** 5000-5999
  - 5030: TV/SD
  - 5040: TV/HD  
  - 5050: TV/UHD
- **Audio:** 3000-3999
  - 3010: Audio/MP3
  - 3040: Audio/Lossless

**Custom Categories (>=100000):**
- Tracker-specific categories
- Use only when necessary
- May not work with all applications

## Security and Privacy Considerations

### VPN Integration

1. **Prowlarr with VPN**
   - Settings → Indexers → Indexer Proxies
   - Add your VPN provider's SOCKS5 proxy
   - Apply to specific indexers that require VPN

2. **Selective VPN Usage**
   - Only use VPN for trackers that require it
   - Most public trackers work without VPN
   - Check local legal requirements

### Safe Browsing

1. **DNS Configuration**
   - Use secure DNS servers (1.1.1.1, 8.8.8.8)
   - Helps with blocked tracker access
   - Improves privacy without VPN complexity

2. **Tracker Access**
   - Some trackers may be blocked by ISPs
   - DNS change often resolves access issues
   - VPN may be required in restrictive countries

Source: https://wiki.servarr.com/vpn

## Indexer Management Best Practices

### Indexer Selection

**Prioritize Quality Sources:**
1. **Private Trackers** (if accessible)
   - Higher quality releases
   - Better retention
   - Faster downloads
   - Scene releases

2. **Established Public Trackers**
   - The Pirate Bay (most comprehensive)
   - 1337x (good variety)
   - RARBG (quality releases, if available)

3. **Specialized Trackers**
   - EZTV for TV shows
   - YTS for movies (smaller file sizes)
   - Nyaa for anime content

### Performance Optimization

1. **Indexer Priority**
   - Set higher priority for quality sources
   - Disable poor-performing indexers
   - Monitor success rates

2. **Rate Limiting**
   - Configure appropriate request intervals
   - Avoid overwhelming trackers
   - Most trackers allow 5-10 requests per minute

3. **Health Monitoring**
   - Regular health checks in Prowlarr
   - Monitor indexer response times
   - Replace failing indexers

### Legal and Ethical Usage

**Important Guidelines:**
- Only download content you legally own
- Respect tracker rules and ratio requirements
- Consider supporting content creators
- Be aware of local copyright laws
- Use VPN where legally required

## Troubleshooting

### Common Issues

1. **Indexer Not Found**
   ```bash
   # Check if indexer is accessible
   curl -I https://tracker-url.com
   
   # Test DNS resolution
   nslookup tracker-url.com 8.8.8.8
   ```

2. **Connection Timeout**
   - Check firewall settings
   - Verify DNS configuration
   - Test with different DNS servers

3. **Private Tracker Authentication**
   - Verify username/password
   - Check API key validity
   - Ensure account is active

4. **Cloudflare Protection**
   - Install and configure FlareSolverr
   - Some sites require manual solving
   - Consider alternative indexers

### Log Analysis

**Prowlarr Logs:**
- Settings → System → Logs
- Look for HTTP errors, timeouts
- Check indexer-specific errors

**Jackett Logs:**
- Available in web interface
- Check for authentication failures
- Monitor rate limiting issues

### Testing Indexer Performance

1. **Manual Search Test**
   - Search for popular recent releases
   - Verify results are returned
   - Check result quality and seeds

2. **Application Integration Test**
   - Add a wanted item in Sonarr/Radarr
   - Monitor search results
   - Verify downloads start correctly

3. **Automated Monitoring**
   - Use built-in health checks
   - Monitor success/failure rates
   - Set up notifications for failures

## Integration Verification

### End-to-End Testing

1. **Add Content to *arr Apps**
   - Add a movie to Radarr
   - Add a TV series to Sonarr
   - Monitor automatic searching

2. **Verify Download Flow**
   - Content appears in qBittorrent
   - Downloads complete successfully
   - Files move to correct directories

3. **Jellyfin Integration**
   - New content appears in Jellyfin
   - Metadata downloads correctly
   - Playback works as expected

### Performance Monitoring

**Key Metrics:**
- Indexer response times
- Search success rates
- Download completion rates
- Failed download handling

**Optimization:**
- Disable underperforming indexers
- Adjust quality profiles based on availability
- Monitor and adjust automation timing

## Next Steps

With indexers configured, proceed to security setup:

**Next Guide:** [VPN and Security Setup](./05-vpn-security-setup.md)

This will ensure safe torrenting practices and protect your privacy during downloads.