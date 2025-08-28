# Force GitHub Through VPN
This script is used for detecting if the NetExtender VPN is connected to an office/server.  If so, it will add routes to force GitHub through the VPN.  This is helpful in situations where IP Whitelisting is enforced and a home dynamic IP does not match to the VPN Gateway IP that may be whitelisted.

# Usage:
## Inject routes
`.\Force-GitHubThroughVPN.ps1`

## Remove routes
`.\Force-GitHubThroughVPN.ps1 --remove`
