# Neovim Configuration

This is a personal Neovim configuration based on `lazy.nvim` and Lua.

## 🚀 Installation & Setup

To use this configuration on a new machine:

### 1. Prerequisites
Ensure you have the following installed:
*   **Neovim** (v0.9.0+ recommended)
*   **Git** (Required for package management)
*   **C Compiler** (gcc or clang) - for compiling Treesitter parsers
*   **Ripgrep** (rg) - for fast searching
*   **Nerd Font** - (Optional) for icons

### 2. Install
Clone this configuration to your Neovim config directory.

**Linux / macOS:**
```bash
git clone <URL_TO_THIS_REPO>/nvim ~/.config/nvim
```

**Windows (PowerShell):**
```powershell
# If this repo is inside 'shell_env', symlink or copy it:
# Option A: Symlink (Recommended)
New-Item -ItemType SymbolicLink -Path "$env:LOCALAPPDATA\nvim" -Target "d:\Projects\shell_env\nvim"

# Option B: Git Clone directly
git clone <URL_TO_THIS_REPO>/nvim "$env:LOCALAPPDATA\nvim"
```

### 3. First Launch
Run `nvim`. 
*   **Lazy.nvim** will automatically install itself.
*   Plugins will be downloaded and installed automatically.
*   Wait for the UI to settle, then run `:checkhealth` to verify everything is working.

## ⌨️ Keymaps
*   **Leader Key:** Space
*   **Window Navigation:** `Alt + h/j/k/l`
*   **File Explorer:** `<C-p>` (if fzf/telescope configured)
*   **Terminal:** Escape via `jk` or `jl` to save.
