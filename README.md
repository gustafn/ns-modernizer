
# Script Overview:
This script helps identify and optionally replace deprecated NaviServer calls with their updated equivalents. **Caution:** Do not rely on this script blindly; review its changes as it serves as a helper tool, not a definitive solution.

## How It Works:
- The script scans all `*.tcl` files within the current directory and its subdirectories.
- Deprecated calls are replaced with updated ones.
- Original files are preserved with the suffix `-original`.


## Basic Usage:
Run the script with the following command to process a directory tree with all subdirectories on all files with the .tcl extension:
```bash
tclsh ns-modernizer.tcl -cd PATH_TO_TCL_FILES
```

**Example:**
```bash
tclsh ns-modernizer.tcl -cd /usr/local/oacs-head/openacs-4/packages/
```

## Advanced Usage:

### 1. Perform Updates:
Use the `-change` flag to update deprecated calls:
```bash
tclsh ns-modernizer.tcl -change 1
```
The script creates backup files by adding "-original" to the  changed files. If you run the script multiple times make sure to delete these backupfile to prevent hickups (see point 5).

### 2. List Differences:
Use the `-diff` flag to review changes without making updates:
```bash
tclsh ns-modernizer.tcl -diff 1
```

### 3. Undo Changes:
Restore files to their original state using the `-reset` flag:
```bash
tclsh ns-modernizer.tcl -reset 1 -change 0
```

### 4. Reset and Reapply Updates:
Reset previous changes and re-run the script:
```bash
tclsh ns-modernizer.tcl -reset 1 -change 1
```

### 5. Clean Up Original Files:
After confirming the updates, remove `-original` backup files to prevent filename clashes:
```bash
find . -name '*-original' -exec rm {} +
```

---

**Note:** Always review the script's changes before applying them to ensure correctness and compatibility with your project.
