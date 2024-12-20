# shell environment

---

Clone this project to Home directory, some rc files hard coded the file paths
to be sourced as `~/shell_env/`.

Just copy the needed rc files to home directory.

## Note

### Zsh

Currently I use `zinit` + `powerlevel10k`. Just copy `.zshrc` to home directory.
And then restart zsh, it will start installing the required files and plugins
at first startup.

May copy `zsh/p10k.default.zsh` or `zsh/p10k.darwin.zsh` to `~/.p10k.zsh` so
that p10k won't go to interactive configure shell.

For more detail, please see their repo.

### Tmux

The lines that load plugins were commented. To use them, first need to install
`tpm`:

``` bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then uncomment the lines that load plugins, go into tmux,
then press `prefix` + <kbd>I</kbd>.

For more detail, please see their repo.

## Misc

### Rust Binaries

Some binaries were better (or fancier) than default Linux command, may install
them via cargo (need install Rust).

* https://github.com/sharkdp/bat
* https://github.com/sharkdp/fd
* https://github.com/Peltoche/lsd
* https://github.com/BurntSushi/ripgrep
* https://github.com/XAMPPRocky/tokei

### Mac

Currently Mac only contains the script for `brew` to install.
However it may not be executed directly, as some may not be supported for M1
natively.

### Windows

Currently only settings for Windows Terminal is attached. But I only leave it
as a reference, I don't think the setting file is portable enough, may need
futher check.
