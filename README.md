# shell environment

---

### This is a shell environment directory.
I only move files to here, having no idea how to automatically allocate them properly.
Waiting for further improvement.

For now there are vimrc, tcshrc, zshrc, tmuxrc

## Note

If you want to use YouCompleteMe in vim, you need to install it manually.
Go to `.vim/plugged/YouCompleteMe` and run the following command:
``` bash
# for Ubuntu 16.04 and later, requires following dependencies
sudo apt install -y build-essential cmake python3-dev
python3 install.py --clang-completer
```
For more detail, please see their repo.

## Tmux

I added some plugins if Tmux is newer than 2.9, however because of how plugins
were implemented, The status is not displayed properly by default, even if the
plugins were installed. The reason is that the status is not updated to the
variable.

To let status to be displayed properly, need to modify the tmux file for each
plugins. For example, after installing the plugins, for tmux-ping to work,
you need to add the line under the main function.

``` bash
# file path: ~/.tmux/plugins/tmux-ping/ping.tmux
update_tmux_option "status-format[1]"
```
