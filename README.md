# wooget 

Wooget 2.0 - a cli to manage all sdk package tasks + bonus content.

## Setup


```ruby
gem sources -a http://gem.sdk.wooga.com/
gem install wooga_wooget
```


## Usage

```ruby
Commands:
  wooget bootstrap            # setup environment / project for wooget usage
  wooget create PACKAGE_NAME  # create a new package
  wooget help [COMMAND]       # Describe available commands or one specific command
  wooget install              # install packages into this unity project
  wooget paket ARGS           # call bundled version of paket and pass args
  wooget paket_unity3d ARGS   # call bundled version of paket.unity3d and pass args
  wooget prerelease           # prerelease package in current dir
  wooget release              # release package in current dir
  wooget test                 # run tests on package in current dir
  wooget update               # update packages into this unity project

Options:
  -v, [--verbose], [--no-verbose]  # Spit out tons of logging info

Runtime options:
  -f, [--force]                    # Overwrite files that already exist
  -q, [--quiet], [--no-quiet]      # Suppress status output
```
