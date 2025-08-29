$ParentPath = "C:\Temp\Target\Directory"
$LogPath = "C:\Temp\logs\DeletedFolders.log"

# Ensure log directory exists
$logDir = Split-Path $LogPath
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

# Find empty folders
$EmptyFolders = Get-ChildItem -Path $ParentPath -Directory -Recurse |
    Where-Object {
        @(Get-ChildItem -LiteralPath $_.FullName -Recurse -Force -File).Count -eq 0
    }

if ($EmptyFolders.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("✅ No empty folders found under $ParentPath", "Empty Folder Check")
} else {
    # Show folders in GridView for review
    $SelectedFolders = $EmptyFolders | Select-Object FullName | Out-GridView -Title "Select folders to delete" -PassThru

    if ($SelectedFolders.Count -gt 0) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogPath -Value "[$timestamp] Deletion started"

        foreach ($folder in $SelectedFolders) {
            try {
                Remove-Item -Path $folder.FullName -Force -Recurse
                Add-Content -Path $LogPath -Value "[$timestamp] Deleted: $($folder.FullName)"
            } catch {
                Add-Content -Path $LogPath -Value "[$timestamp] Failed to delete: $($folder.FullName) - $_"
            }
        }

        Add-Content -Path $LogPath -Value "[$timestamp] Deletion completed`n"
        [System.Windows.Forms.MessageBox]::Show("🧹 Selected folders deleted and logged to $LogPath", "Deletion Complete")
    } else {
        [System.Windows.Forms.MessageBox]::Show("🚫 No folders were selected for deletion.", "No Action Taken")
    }
}