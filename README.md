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
  wooget create PACKAGE_NAME  # create a new package
  wooget help [COMMAND]       # Describe available commands or one specific command
  wooget paket ARGS           # call bundled version of paket and pass args
  wooget paket_unity3d ARGS   # call bundled version of paket.unity3d and pass args
  wooget prerelease           # prerelease package
  wooget release              # release package
  wooget setup                # setup environment for wooget usage
  wooget test                 # run tests on package in current dir

Options:
  -v, [--verbose], [--no-verbose]  # Log level
```
