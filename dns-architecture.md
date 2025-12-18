# DNS Architecture Documentation

## Target Dual-DNS Architecture

### Host Configuration Summary

| Host | IP Address | Tailscale IP | useResolved | DNS Role | Uptime |
|------|------------|-------------|-------------|----------|---------|
| aspen | 192.168.1.2 | 100.68.250.108 | false | LAN DNS server (Pi-hole + Unbound) | ~85% |
| juniper | 178.156.133.218 | 100.70.221.14 | false | Tailscale DNS server (Pi-hole + Unbound) | ~99% |
| thinkpad | 192.168.1.62 | 100.66.143.66 | true | Client | - |
| cypress | 192.168.1.89 | 100.84.248.69 | true | Client | - |
| alder | 192.168.4.15 | 100.68.185.99 | true | Client | - |

**Note**: juniper's `useResolved` will change to `false` when Pi-hole is deployed.

## Architecture Overview

### DNS Infrastructure

| Host | DNS Role | Configuration | Network Scope |
|------|----------|---------------|---------------|
| aspen | LAN DNS server | Pi-hole + Unbound (declarative via `oci-pihole-test.nix`) | LAN devices, fallback for Tailscale |
| juniper | Tailscale DNS server | Pi-hole + Unbound (declarative via `oci-pihole-test.nix`) | Tailscale devices (primary) |

### systemd-resolved vs Manual resolv.conf

**aspen (useResolved = false):**
- Uses manual `/etc/resolv.conf`:
  ```
  nameserver 127.0.0.1  # Local Pi-hole
  nameserver 1.1.1.1    # Cloudflare fallback
  ```
- Reason: Runs Pi-hole locally, needs to avoid conflicts with systemd-resolved

**juniper (useResolved = false):** [after Pi-hole deployment]
- Uses manual `/etc/resolv.conf`:
  ```
  nameserver 127.0.0.1  # Local Pi-hole
  nameserver 1.1.1.1    # Cloudflare fallback
  ```
- Reason: Will run Pi-hole locally, needs to avoid conflicts with systemd-resolved

**All other hosts (useResolved = true):**
- Use systemd-resolved for DNS management
- Receive DNS servers via DHCP (LAN) or Tailscale configuration
- systemd-resolved automatically handles DNS source priority

### Architecture Diagram

```
                          DUAL PI-HOLE + UNBOUND ARCHITECTURE

    ┌─────────────────────────┐                    ┌─────────────────────────┐
    │     JUNIPER (VPS)        │                    │     ASPEN (HOME)        │
    │    99% UPTIME            │                    │    85% UPTIME           │
    │   178.156.133.218        │                    │   192.168.1.2 (LAN)     │
    │   100.70.221.14 (TS)     │                    │   100.68.250.108 (TS)   │
    │                          │                    │                         │
    │  resolv.conf:            │    IDENTICAL       │  resolv.conf:           │
    │    nameserver 127.0.0.1  │    DECLARATIVE     │    nameserver 127.0.0.1 │
    │    nameserver 1.1.1.1    │    CONFIGURATION   │    nameserver 1.1.1.1   │
    ├─────────────────────────┤       (NIX)        ├─────────────────────────┤
    │ Pi-hole   │   Unbound    │◄─────────────────►│ Pi-hole   │   Unbound   │
    │ 172.21.1.2│   172.21.1.3 │                    │ 172.21.1.2│   172.21.1.3│
    │           │              │                    │           │             │
    │ • Ad blocking           │                    │ • Ad blocking           │
    │ • Custom DNS entries    │                    │ • Custom DNS entries    │
    │ • CNAME records         │                    │ • CNAME records         │
    │ • Privacy-focused       │                    │ • Privacy-focused       │
    │ • DNSSEC validation     │                    │ • DNSSEC validation     │
    └───────────┴─────────────┘                    └───────────┴─────────────┘
             ▲                                                  ▲
             │                                                  │
             │                                                  │
    ┌────────┴──────────┐                            ┌─────────┴──────────────┐
    │  TAILSCALE DEVICES│                            │   LAN DEVICES          │
    │                   │                            │   (Roku, IoT, etc.)    │
    │  Primary DNS:     │                            │                        │
    │  100.70.221.14    │                            │  DNS Server:           │
    │                   │                            │  192.168.1.2           │
    │  Fallback DNS:    │                            │                        │
    │  100.68.250.108   │                            │  No fallback           │
    │                   │                            │  (single point of      │
    │  (Auto failover   │         ┌──────────┐       │   failure accepted)    │
    │   via Tailscale)  │◄────────┤TAILSCALE │──────►│                        │
    └───────────────────┘         │ OVERRIDE │       └────────────────────────┘
                                  │   DNS    │                ▲
                                  └──────────┘                │
                                                             │
                                                    ┌────────┴──────────┐
                                                    │   UNIFI DHCP      │
                                                    │   (on aspen)      │
                                                    │                   │
                                                    │ Hands out:        │
                                                    │ 192.168.1.2       │
                                                    │ (no fallback)     │
                                                    └───────────────────┘
                                                             │
                                               Root DNS ◄────┴────► Root DNS
                                               Servers              Servers
```

### DNS Distribution Strategy

#### Tailscale Override DNS Configuration
```
Primary:   100.70.221.14  (juniper - 99% uptime)
Secondary: 100.68.250.108 (aspen - 85% uptime)
```
- **Rationale**: Prioritize high-uptime VPS for Tailscale-capable devices
- **Benefit**: Tailscale devices get redundant DNS with automatic failover

#### UniFi DHCP Configuration (No Change)
```
DNS Server: 192.168.1.2 (aspen)
```
- **Rationale**: Local DNS for best performance, no Tailscale dependency
- **Limitation**: Non-Tailscale devices (Roku, IoT) have single point of failure
- **Trade-off**: Accepted for simplicity; these devices need local network anyway

### How DNS Resolution Works

#### For Hosts with Tailscale
1. **When on LAN + Tailscale connected**: Uses juniper (100.70.221.14) via Tailscale override
2. **When on LAN + Tailscale disconnected**: Falls back to aspen (192.168.1.2) via DHCP
3. **When remote + Tailscale connected**: Uses juniper (100.70.221.14) via Tailscale
4. **Automatic failover**: If juniper is down, Tailscale automatically uses aspen

#### For Non-Tailscale Devices (Roku, IoT)
1. **Always**: Uses aspen (192.168.1.2) via UniFi DHCP
2. **No redundancy**: Single point of failure accepted for these devices
3. **Rationale**: These devices typically need local services anyway (can't stream when internet/aspen is down)

### Implementation with Declarative Configuration

#### Using `oci-pihole-test.nix`
Both aspen and juniper will use the same declarative configuration:
- **Identical blocklists** via `piholeAdlists` list
- **Identical custom DNS entries** via `customDnsEntries`
- **Identical CNAME records** via `customCnameEntries`
- **No state synchronization needed** - Nix ensures consistency

### DNS Resolution Details

#### Pi-hole Container Configuration
Both aspen and juniper run identical Pi-hole + Unbound containers:
- **Pi-hole**: `172.21.1.2` (ad/malware blocking, custom DNS records)
- **Unbound**: `172.21.1.3` (privacy-focused recursive DNS resolver)
- **Docker Network**: `172.21.1.0/25` (isolated pihole subnet)

## Benefits of This Architecture

### High Availability
1. **Tailscale devices**: 99% DNS uptime (juniper primary, aspen fallback)
2. **Automatic failover**: Tailscale handles DNS failover transparently
3. **Geographic distribution**: VPS + home server redundancy
4. **No single point of failure**: For Tailscale-capable devices

### Privacy & Security
1. **No external DNS reliance**: Both instances use Unbound for recursive resolution
2. **DNSSEC validation**: Cryptographic verification of DNS responses
3. **Ad/malware blocking**: Comprehensive blocklists on both instances
4. **Local service resolution**: Internal services resolved without external queries

## Known Limitations & Trade-offs

### Limitations
1. **Non-Tailscale devices**: Single point of failure on aspen (accepted trade-off)
2. **Docker DNS circular dependency**: aspen still vulnerable during image updates
3. **Increased complexity**: Two Pi-hole instances to maintain (mitigated by declarative config)
4. **Network segmentation**: LAN devices can't directly use juniper as fallback

## Implementation Plan

### Phase 1: Finalize Declarative Configuration
- Complete `oci-pihole-test.nix` development on aspen
- Test all DNS resolution paths
- Validate ad blocking and custom DNS entries
- Ensure container startup reliability

### Phase 2: Deploy to Juniper
- Update `juniper/configuration.nix` to import `oci-pihole-test.nix`
- Change `useResolved = true` to `useResolved = false` in vars file
- Deploy and test Pi-hole on juniper
- Verify identical configuration via Nix

### Phase 3: Update DNS Distribution
- Tailscale admin console: Update override DNS to `100.70.221.14, 100.68.250.108`
- Test Tailscale DNS resolution and failover
- Verify all Tailscale devices receive new DNS configuration

### Phase 4: Monitor & Validate
- Monitor DNS resolution performance on both instances
- Test failover scenarios (aspen down, juniper down)
- Validate ad blocking effectiveness on both instances
- Document any edge cases or issues