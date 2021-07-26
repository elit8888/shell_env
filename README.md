# shell environment

---

Clone this project to Home directory, some rc files hard coded the file paths
to be sourced as `~/shell_env/`.

Just copy the needed rc files to home directory.

## Note

### Vim

#### YouCompleteMe

If you want to use YouCompleteMe in vim, you need to install it manually.
Go to `.vim/plugged/YouCompleteMe` and run the following command:

``` bash
# for Ubuntu 16.04 and later, requires following dependencies
sudo apt install -y build-essential cmake pytho3-dev
# support C++ completion
python3 install.py --clang-completer
```

For C / C++, may have a config file for YCM to have customized compile option:

``` python
# .ycm_extra_conf.py

def Settings(**kwargs):
  return {
    "flags": ["-x", "c++", "-std=c++17", "-Wall", "-Wextra", "-Werror"],
  }
```

For more detail, please see their repo.

#### C / C++ Trace Code

Need to install ctags & cscope

``` bash
sudo apt install exuberant-ctags cscope
```

Then go to the project root, type the following commands to generate tags:

``` bash
ctags -R
cscope -Rbqk
# You may also need to put the file http://cscope.sourceforge.net/cscope_maps.vim
# into vimpath, like ~/.vim/cscope_maps.vim
```


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

### Mac

Currently Mac only contains the script for `brew` to install.
However it may not be executed directly, as some may not be supported for M1
natively.

### Windows

Currently only settings for Windows Terminal is attached. But I only leave it
as a reference, I don't think the setting file is portable enough, may need
futher check.
