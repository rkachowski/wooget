# wooget 

Wooget 2.0 - a cli to manage all sdk package tasks + bonus content.

## Features

* Sets up your unity project to work with wooget packages
* Installs your packages
* Updates your packages
* Lists latest versions of everything available
* Creates new packages for you
* Builds new packages for you
* Releases new packages for you
* Does everything, just for you

> Checkout [the wiki](https://github.com/wooga/wooget/wiki/) for more information

## Setup

```ruby
gem sources -a http://gem.sdk.wooga.com/
gem install wooga_wooget
```

## Usage

```
Commands:
  wooget bootstrap                # setup environment / project for wooget usage
  wooget build --version=VERSION  # build the packages in the current dir
  wooget create PACKAGE_NAME      # create a new package
  wooget help [COMMAND]           # Describe available commands or one specific command
  wooget install                  # install packages into this unity project
  wooget list                     # list available packages + version
  wooget paket ARGS               # call bundled version of paket and pass args
  wooget paket_unity3d ARGS       # call bundled version of paket.unity3d and pass args
  wooget prerelease               # prerelease package in current dir
  wooget release                  # release package in current dir
  wooget search                   # search packages by a regex
  wooget test                     # run package tests in mono
  wooget update                   # update packages into this unity project

Options:
  -v, [--verbose], [--no-verbose]  # Spit out tons of logging info
  -q, [--quiet], [--no-quiet]      # Suppress stdout
      [--path=PATH]                # Path to the project you want to install things into
                                   # Default: /Users/donaldhutchison/workspace/wooget

```

