# AWS VGW and VPN Bandwidth Limitations & Tunnel Configurations

## Original Question
Can you teach me about the limitations of AWS VGWS bandwidth-wise? I forgot what was 1.25 gbps and how get 5 gbps if its possible, or how to have many tunnels and how many tunnels you can have max for given setups (without TGW, with TGW, etc.)

## Comprehensive Answer

### Per-Tunnel Bandwidth Limitations
- **1.25 Gbps** - Maximum throughput per VPN tunnel (hard limit)
- **140,000 PPS** - Maximum packets per second per tunnel
- Each AWS Site-to-Site VPN connection automatically creates 2 tunnels for high availability

### Virtual Private Gateway (VGW) Limits - Without Transit Gateway

#### Bandwidth Constraints
- **1.25 Gbps aggregate throughput** - Multiple VPN connections to the same VGW are bound by this aggregate limit
- **No ECMP support** - VGW does not support Equal Cost Multi-Path routing, preventing load balancing across tunnels

#### Connection Limits
- **10 VPN connections maximum** per VGW
- **2 tunnels per VPN connection** (20 tunnels total maximum)
- **1 VGW per VPC** - Only one Virtual Private Gateway can be attached to a VPC at a time

#### Routing Limits
- **1,000 routes** maximum advertised from AWS to customer gateway
- **100 routes** maximum advertised from customer gateway to VGW
- **100 static routes** maximum for VPN connections using static routing

### Transit Gateway (TGW) - Scaling Beyond 1.25 Gbps

#### Bandwidth Scaling with ECMP
- **Up to 50 Gbps aggregate throughput** using ECMP across multiple VPN connections
- **Requirement:** Must use dynamic routing (BGP) to enable ECMP
- **Per-flow limitation:** Individual traffic flows still limited to 1.25 Gbps per tunnel

#### How to Achieve 5 Gbps
1. Use Transit Gateway instead of Virtual Private Gateway
2. Enable ECMP (dynamic routing option must be enabled)
3. Create at least 4 VPN connections (8 tunnels total)
4. Traffic will load-balance across all tunnels

#### Connection & Attachment Limits
- **5,000 VPC attachments** maximum per Transit Gateway
- **Site-to-Site VPN connections** count toward total attachment limit
- **1,000 routes** maximum advertised from customer gateway to TGW
- **10,000 routes** default limit per Transit Gateway route table

### Transit Gateway Connect (GRE)
- **5 Gbps** maximum throughput per Connect peer (GRE tunnel)
- **4 Connect peers** maximum per Connect attachment
- **20 Gbps** total bandwidth per Connect attachment

### MTU Considerations
- **1446 bytes** MTU for Site-to-Site VPN
- **1406 bytes** MSS (Maximum Segment Size)
- **8500 bytes** MTU for TGW traffic between VPCs, Direct Connect, and peering attachments
- **1500 bytes** MTU for traffic over VPN connections on TGW

### Summary Table

| Component | Max VPN Connections | Tunnels per Connection | Max Aggregate Bandwidth | ECMP Support |
|-----------|-------------------|----------------------|----------------------|--------------|
| **VGW** | 10 | 2 (20 total) | 1.25 Gbps | No |
| **TGW** | Limited by attachment quota | 2 | 50 Gbps | Yes (with BGP) |

### Key Recommendations
- For bandwidth requirements beyond 1.25 Gbps, Transit Gateway is mandatory
- VGW cannot scale beyond 1.25 Gbps even with multiple VPN connections
- Each VPN connection always creates 2 tunnels for redundancy
- ECMP with Transit Gateway is the only way to aggregate bandwidth across multiple tunnels

## Sources Referenced

1. **AWS Site-to-Site VPN quotas**
   - URL: https://docs.aws.amazon.com/vpn/latest/s2svpn/vpn-limits.html

2. **Scaling VPN throughput using AWS Transit Gateway**
   - URL: https://aws.amazon.com/blogs/networking-and-content-delivery/scaling-vpn-throughput-using-aws-transit-gateway/

3. **AWS Transit Gateway Quotas**
   - URL: https://docs.aws.amazon.com/vpc/latest/tgw/transit-gateway-quotas.html

4. **Amazon VPC quotas**
   - URL: https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html

5. **AWS VPN FAQs**
   - URL: https://aws.amazon.com/vpn/faqs/

## Key Documentation Quotes

### On VGW Bandwidth Limitations
> "Multiple VPN connections to the same Virtual Private Gateway are bound by an aggregate throughput limit from AWS to on-premises of up to 1.25 Gbps"
- Source: AWS Site-to-Site VPN documentation

> "VPN throughput to a VGW is limited to 1.25 Gbps per tunnel and ECMP load balancing is not supported"
- Source: AWS Networking Blog on Scaling VPN throughput

### On Transit Gateway Scaling
> "AWS Transit Gateway enables you to scale the IPsec VPN throughput with equal cost multi-path (ECMP) routing support over multiple VPN tunnels"
- Source: AWS Transit Gateway documentation

> "The maximum bandwidth of a combined (using ECMP) set of VPNs is 50 Gb/s"
- Source: AWS VPN documentation

### On Connection Limits
> "The VGW can only have ten VPN connections"
- Source: AWS VPC documentation

> "Each AWS Site-to-Site VPN connection has two tunnels"
- Source: AWS Site-to-Site VPN documentation

### On Tunnel Specifications
> "Each tunnel supports a maximum throughput of up to 1.25 Gbps"
- Source: AWS Site-to-Site VPN quotas

> "Site-to-Site VPN supports a maximum transmission unit (MTU) of 1446 bytes and a corresponding maximum segment size (MSS) of 1406 bytes"
- Source: AWS Site-to-Site VPN documentation

### On ECMP Requirements
> "You must enable the dynamic routing option on your transit gateway to be able to take advantage of ECMP for scalability"
- Source: AWS Transit Gateway documentation

> "To use ECMP, the VPN connection must be configured for dynamic routing. ECMP is not supported on VPN connections that use static routing"
- Source: AWS Site-to-Site VPN documentation

### On Route Advertisements
> "Your VPN connection will advertise a maximum of 1,000 routes to the customer gateway device"
- Source: AWS Site-to-Site VPN quotas

> "You can advertise a maximum of 100 routes to your Site-to-Site VPN connection on a virtual private gateway from your customer gateway device or a maximum of 1000 routes to your Site-to-Site VPN connection on an AWS Transit Gateway"
- Source: AWS Site-to-Site VPN documentation

## Additional Notes

- **2025 Status:** These limits remain current as of 2025 based on the latest AWS documentation
- **Best Practice:** For any deployment requiring more than 1.25 Gbps or more than 10 VPN connections, Transit Gateway should be the default choice
- **Cost Consideration:** Transit Gateway incurs additional charges compared to VGW, but provides significantly more flexibility and scalability