Put host-specific overrides in folders named after `$(hostname)`.

Example:
```
hosts/my-mac/zshrc.host.zsh
hosts/my-mac/gitconfig.host
```
They will be sourced automatically by `bin/bootstrap`.
