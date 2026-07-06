#!/bin/bash

export ROOT_FOLDER=/Users/Shared/Projects/d/hw/dotnet-tools/tree-sitter/HW.DotNet.Parsers.Generators.TreeSitter.Private/source/business-domain-logic/

export GRAMMARS=\
"
Bash
Bicep
C
CSharp
CapnP
Cpp
CSS
CSV
Diff
Go
Haskell
HTML
Java
JavaScript
JSON
Julia
Kotlin
Make
ObjC
PHP
PowerShell
Puppet
Python
R
RegEx
Ruby
Rust
Scala
SCSS
Swift
Thrift
TOML
TypeScript
XML
YAML
"

export PROFILES=\
"
Balanced
Debug
Size
Speed
"

IFS=$'\n'
# ZSH does not split words by default (like other shells):
setopt sh_word_split

for GRAMMAR in $GRAMMARS
do
    if [[ $GRAMMAR == "#"* ]]
    then
        echo "......................................................................"
        echo $GRAMMAR
        continue
    fi

    for PROFILE in $PROFILES
    do
        if [[ $PROFILE == "#"* ]]
        then
            echo "......................................................................"
            echo $PROFILE
            continue
        fi
        echo "Grammar: $GRAMMAR"
        dotnet \
            new \
                classlib \
                --output $ROOT_FOLDER/grammars/$GRAMMAR/HolisticWare.Tools.Parsers.Generators.TreeSitter.$GRAMMAR.$PROFILE \

    done

done

