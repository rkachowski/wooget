# wooget 

A cli which allows [Unity3d](http://www.unity3d.com) projects to work with NuGet packages.

## Features

* Configures Unity3d to work with NuGet
* Install and update packages
* List and search available packages
* Create, Build, Test and Release new NuGet packages

> Checkout [the wiki](https://github.com/wooga/wooget/wiki/) for more information

## Install

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

