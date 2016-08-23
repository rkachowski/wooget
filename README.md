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

## Setup

```ruby
gem sources -a http://gem.sdk.wooga.com/
gem install wooga_wooget
```

## Usage

```
$ wooget help
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
                                   # Default: /Users/donaldhutchison/workspace/wdk-wooget
```

## Config

### Default config
On first usage a config file will be created in your home directory under `~/.wooget`. This contains all the information about which repostiories and credentials to use when uploading / downloading packages. 

### Github
You can also use the tool to create github releases for your packages, which will trigger sdk-bot messages (as well as provide a backup location for packages should artifactory go down). To use this you need to generate and add a github oauth token to the config file.

Follow [the official github instructions on how to generate a token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) and add it to the config file under the `credentials` key, with the name `github_token`.

Ultimately, the config should look like

```
{
    "credentials": 
    {
        "username": "sdk-universe-user",
        "password": "the password",
        "github_token":"your token"
    },
    "repos":
    {
        "universe":"https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-universe",
        "main":"https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-main",
        "legacy":"https://wooga.artifactoryonline.com/wooga/api/nuget/nuget-private",
        "default":"https://wooga.artifactoryonline.com/wooga/api/nuget/sdk-main"
    }
}
```
