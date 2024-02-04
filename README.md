# Dotnet-squire
A plugin to provide helper functionality related to dotnet development.
## Installation
### Lazy
Follow the instructions below to install the plugin using [Lazy](https://github.com/folke/lazy.nvim):

Add the following to your Lazy `setup` table:
```
{
  'YanikCeulemans/dotnet-squire',
  config = true,
}
```

### Packer
Add the following snippet to your packer setup:
```
use {
  'YanikCeulemans/dotnet-squire',
  config = function()
    require('dotnet-squire').setup()
  end
}
```

## Features
- dotnet secrets management

## Secrets management
The command `:Secrets` will open the `secrets.json` file for either the current dotnet project, or when you have multiple projects in subdirectories, it will allow you to choose which one. If the chosen project doesn't already have user secrets defined, the command will suggest initializing user-secrets for that project. The `secrets.json` file will open in the current buffer, if you want it to open in a split, you can use the command `:new | Secrets` for example.

