# Package Lists

This directory contains lists of packages to be installed.

## Files

- **apt-manual-packages.txt** - Manually installed packages (recommended for restoration)
- **apt-packages.txt** - All installed packages (complete list for reference)
- **flatpak-packages.txt** - Flatpak applications (if any)
- **snap-packages.txt** - Snap packages (if any)

## Generating Package Lists

To update package lists from your current system:

```bash
# Manually installed packages (excludes dependencies)
apt-mark showmanual > apt-manual-packages.txt

# All installed packages
dpkg --get-selections | grep -v deinstall | awk '{print $1}' > apt-packages.txt

# Flatpak packages
flatpak list --app --columns=application > flatpak-packages.txt

# Snap packages
snap list | tail -n +2 | awk '{print $1}' > snap-packages.txt
```

## Notes

- The setup script uses `apt-manual-packages.txt` by default
- Comments (lines starting with #) are ignored
- Empty lines are ignored
- Packages not available on target system will be skipped with warning
