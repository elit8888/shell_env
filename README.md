# shell environment

---

Clone this project to Home directory, some rc files hard coded the file paths
to be sourced as `~/shell_env/`.

Just copy the needed rc files to home directory.

## Note

### Vim

If you want to use YouCompleteMe in vim, you need to install it manually.
Go to `.vim/plugged/YouCompleteMe` and run the following command:

``` bash
# for Ubuntu 16.04 and later, requires following dependencies
sudo apt install -y build-essential cmake pytho3-dev
# support C++ completion
python3 install.py --clang-completer
```

For more detail, please see their repo.


### Zsh

Currently I use `zinit` + `powerlevel10k`. Just copy `.zshrc` to home directory.
And then restart zsh, it will start installing the required files and plugins
at first startup.

May copy `zsh/p10k.default.zsh` or `zsh/p10k.darwin.zsh` to `~/.p10k.zsh` so
that p10k won't go to configure shell.

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

