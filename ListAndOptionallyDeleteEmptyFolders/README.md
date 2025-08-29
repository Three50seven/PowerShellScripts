# List and Optionally Delete Empty Folders
This script is used for listing empty folders and gives an options to delete them, if any are found.  This checks for true emptiness - no files in the folder or any subfolder.  It uses `-Force` to include hidden/system files in the check.

An example use-case might be to clean up movie or music file directories, where files might be renamed by the management app (e.g. iTunes, Plex, etc.).

# Usage:
## Run script
`.\ListAndOptionallyDeleteEmptyFolders.ps1`

A message box window appears if any empty folders are found.  You can then select which folders to delete and press 'ok' to delete them or press 'cancel' to exit.