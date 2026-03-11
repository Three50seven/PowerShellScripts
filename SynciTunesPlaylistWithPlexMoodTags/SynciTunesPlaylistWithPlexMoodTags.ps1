# --- Configuration ---
$PlexUrl = "https://192.168.1.xxx:32400"
# Plex Token: You can find this by signing into Plex Web, clicking "Get Info" on any track, then clicking "View XML" at the bottom. The token is at the end of the URL in your browser address bar (X-Plex-Token=...).
$PlexToken = "X-YourTokenGoesHere"
$ItunesXmlPath = "C:\Path\To\iTunes Music Library.xml"
$CsvPath = "C:\Path\To\sync_config.csv"

# --- Helper: Update Plex Mood ---
function Update-PlexMood {
    param([string]$BaseUrl, [string]$Token, [string]$RatingKey, [string]$MoodName, [string]$Action)
    
    if ([string]::IsNullOrWhiteSpace($RatingKey)) { return }
    $EncodedMood = [Uri]::EscapeDataString($MoodName)
    
    # We use 'mood.tag' which is more universal for track updates
    $TagOp = if ($Action -eq "add") { "mood[].tag.tag=$EncodedMood" } else { "mood[].tag.tag-=$EncodedMood" }
    
    $UpdateUrl = "$($BaseUrl)/library/metadata/$($RatingKey)?$($TagOp)&X-Plex-Token=$($Token)"
    
    try {
        $null = Invoke-RestMethod -Uri $UpdateUrl -Method Put -ErrorAction Stop
    } catch {
        Write-Warning "Failed update on ID $($RatingKey): $($_.Exception.Message)"
    }
}

# --- Helper: Get Tracks by Mood ---
function Get-PlexMoodData {
    param($BaseUrl, $Token, $SectionId, $Mood)
    # Using 'mood' filter in the library all view
    $Url = "$($BaseUrl)/library/sections/$($SectionId)/all?type=10&mood=$([Uri]::EscapeDataString($Mood))&X-Plex-Token=$($Token)"
    try {
        $res = Invoke-RestMethod -Uri $Url -Method Get
        $tracks = @($res.MediaContainer.Track)
        return $tracks | Where-Object { $_.ratingKey }
    } catch { return @() }
}

# 1. Startup
Write-Host "--- Initializing Mood-Based Sync ---" -ForegroundColor Cyan
[xml]$xml = Get-Content $ItunesXmlPath
$config = Import-Csv $CsvPath

# Discovery
$SectionsUrl = "$($PlexUrl)/library/sections?X-Plex-Token=$($PlexToken)"
$sections = Invoke-RestMethod -Uri $SectionsUrl -Method Get
$MusicSectionId = (@($sections.MediaContainer.Directory) | Where-Object { $_.type -eq "artist" } | Select-Object -First 1).key

# 2. Process Playlists
foreach ($row in $config) {
    $TargetPlaylistName = $row.PlaylistName
    $TagName = $row.LabelName 

    Write-Host "`n>>> SYNCING: $TargetPlaylistName -> Mood: $TagName" -ForegroundColor White -BackgroundColor DarkMagenta

    $playlistNode = $xml.plist.dict.array.dict | Where-Object { $_.string -contains $TargetPlaylistName }
    if (-not $playlistNode) { Write-Warning "Playlist '$TargetPlaylistName' not found in iTunes."; continue }
    
    $itunesTrackIds = @($playlistNode.array.dict.integer)
    Write-Host " [iTunes] Tracks: $($itunesTrackIds.Count)"

    # Get Plex current state
    $existingTracks = Get-PlexMoodData -BaseUrl $PlexUrl -Token $PlexToken -SectionId $MusicSectionId -Mood $TagName
    $initialCount = $existingTracks.Count
    $plexTaggedKeys = @($existingTracks.ratingKey) | ForEach-Object { [string]$_ }
    
    Write-Host " [Plex] Currently identified with this mood: $initialCount" -ForegroundColor Gray
    
    $processedPlexKeys = @()

    # 3. ADD Pass
    foreach ($id in $itunesTrackIds) {
        $node = $xml.SelectSingleNode("//key[text()='$id']/following-sibling::dict[1]")
        $title = $node.SelectSingleNode("key[text()='Name']/following-sibling::string[1]").InnerText
        $artist = $node.SelectSingleNode("key[text()='Artist']/following-sibling::string[1]").InnerText

        # Targeted search: type=10 ensures we only find tracks
        $SearchUrl = "$($PlexUrl)/library/sections/$($MusicSectionId)/search?type=10&title=$([Uri]::EscapeDataString($title))&artist=$([Uri]::EscapeDataString($artist))&X-Plex-Token=$($PlexToken)"
        $searchRes = Invoke-RestMethod -Uri $SearchUrl -Method Get
        $pTrack = @($searchRes.MediaContainer.Track) | Select-Object -First 1

        if ($pTrack -and $pTrack.ratingKey) {
            $keyStr = [string]$pTrack.ratingKey
            $processedPlexKeys += $keyStr
            
            # If not already tagged in our initial check, tag it
            if ($keyStr -notin $plexTaggedKeys) {
                Update-PlexMood -BaseUrl $PlexUrl -Token $PlexToken -RatingKey $keyStr -MoodName $TagName -Action "add"
                Write-Host "   + Added Mood: $artist - $title (ID: $keyStr)" -ForegroundColor Green
            }
        }
    }

    # 4. REMOVE Pass
    # Only remove if it was in the ORIGINAL plex set but NOT in the NEW itunes set
    foreach ($key in $plexTaggedKeys) {
        if ($key -notin $processedPlexKeys) {
            Update-PlexMood -BaseUrl $PlexUrl -Token $PlexToken -RatingKey $key -MoodName $TagName -Action "remove"
            Write-Host "   - Removed Mood: ID $key" -ForegroundColor Yellow
        }
    }

    $finalTracks = Get-PlexMoodData -BaseUrl $PlexUrl -Token $PlexToken -SectionId $MusicSectionId -Mood $TagName
    Write-Host " [Result] Mood Count: $initialCount -> $($finalTracks.Count)" -ForegroundColor Cyan
}

Write-Host "`nAll sync tasks finished." -ForegroundColor Green