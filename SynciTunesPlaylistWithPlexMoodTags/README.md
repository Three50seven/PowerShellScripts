# Sync iTunes Playlist with Plex Mood Tags
This project allows you to sync your iTunes playlists with Plex mood tags. It uses the iTunes library file (e.g. Itunes Music Library.xml) to retrieve your playlists and the Plex API to update the mood tags accordingly.

## Note
- Ensure that your Plex server is accessible on the same network the script is running and that you have the correct token with the necessary permissions to update mood tags.PlaylistName,LabelName

## Configuration
Update Configuration settings before running the script:
- $PlexUrl = "https://192.168.1.xxx:32400"
- $PlexToken = "X-YourTokenGoesHere"
    - Plex Token: You can find this by signing into Plex Web, clicking "Get Info" on any track, then clicking "View XML" at the bottom. The token is at the end of the URL in your browser address bar (X-Plex-Token=...).
- $ItunesXmlPath = "C:\Path\To\iTunes Music Library.xml"
- $CsvPath = "C:\Path\To\sync_config.csv"
    - The format of the CSV file should be:
    ```
    PlaylistName,LabelName
    Chill Vibes, Chill
    Workout, Energetic
    ```
## Usage
After running the script, the tracks in Plex matching the tracks from iTunes in the specified playlists will have the corresponding mood tags applied. You can verify the changes in Plex by checking the track details for the applied mood tags.

You can create smart playlists in Plex based on these mood tags to easily access your synced playlists. For example, you can create a smart playlist that includes all tracks with the "Chill" mood tag to access your "Chill Vibes" playlist from iTunes in Plex.

## Automation
To automate this process, you can set up a scheduled task in Windows to run the script at regular intervals (e.g., daily or weekly) to keep your Plex mood tags in sync with your iTunes playlists.
