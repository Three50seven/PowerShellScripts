param (
    [switch]$Remove
)

# VPN Gateway IP
$vpnGateway = "<Add VPN Gateway IP here>"

# Convert CIDR to netmask
function ConvertTo-NetMask {
    param([int]$bits)
    $mask = [math]::Pow(2, 32) - [math]::Pow(2, 32 - $bits)
    return [System.Net.IPAddress]::new($mask).ToString()
}

# Fetch GitHub IP ranges
function Get-GitHubSubnets {
    try {
        $meta = Invoke-RestMethod -Uri "https://api.github.com/meta" -UseBasicParsing
        return $meta.git
    } catch {
        Write-Error "❌ Failed to fetch GitHub IP ranges: $_"
        return @()
    }
}

# Show current routes
function Show-Routes {
    Write-Host "`n📋 Current route table snapshot:"
    Get-NetRoute | Sort-Object DestinationPrefix | Format-Table -AutoSize
}

# Add routes
function Add-GitHubRoutes {
    param([string[]]$subnets)

    foreach ($subnet in $subnets) {
        $parts = $subnet -split "/"
        $ip = $parts[0]
        $maskBits = [int]$parts[1]
        $mask = ConvertTo-NetMask $maskBits

        Write-Host "➕ Adding route for $subnet via $vpnGateway"
        route add $ip mask $mask $vpnGateway metric 1 -p
    }
}

# Remove routes
function Remove-GitHubRoutes {
    param([string[]]$subnets)

    foreach ($subnet in $subnets) {
        $parts = $subnet -split "/"
        $ip = $parts[0]
        $maskBits = [int]$parts[1]
        $mask = ConvertTo-NetMask $maskBits

        Write-Host "🗑️ Removing route for $subnet"
        route delete $ip mask $mask
    }
}

# Detect NetExtender VPN connection
function Test-NetExtenderConnection {
    $vpnProcess = Get-Process -Name "NetExtender" -ErrorAction SilentlyContinue
    $vpnRoute = Get-NetRoute | Where-Object { $_.NextHop -eq $vpnGateway }

    if ($vpnProcess -and $vpnRoute.Count -gt 0) {
        Write-Host "🔒 NetExtender VPN is active."
        return $true
    } else {
        Write-Warning "🚫 NetExtender VPN not detected. Aborting route changes."
        return $false
    }
}

# Main Execution
Show-Routes

$subnets = Get-GitHubSubnets

if (-not $subnets) {
    Write-Warning "No GitHub subnets retrieved. Exiting."
    exit 1
}

if (-not (Test-NetExtenderConnection)) {
    exit 1
}

if ($Remove) {
    Remove-GitHubRoutes -subnets $subnets
    Write-Host "`n✅ Cleanup complete."
} else {
    Add-GitHubRoutes -subnets $subnets
    Write-Host "`n✅ GitHub traffic is now routed through VPN."
}

Show-Routes