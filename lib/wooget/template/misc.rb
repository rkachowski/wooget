module Wooget
  module Templates
    def self.readme options
<<HERE

## #{options[:name]}

### Summary

A cool package

### Description



### Usage

```csharp
var coolness = Cool.Package("yeah");
coolness.Execute();

```

*author: #{options[:author]}*
HERE
    end

    def self.gitignore
<<HERE
*bin
*obj
*.vs
*AssemblyInfo.cs
packages
HERE
    end
  end
end
