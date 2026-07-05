#!/bin/bash

export URLS_CORE_N_GRAMMARS=\
"
https://github.com/tree-sitter/tree-sitter-c-sharp/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-markdown/archive/refs/heads/split_parser.zip
https://github.com/tree-sitter/tree-sitter-c/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-cpp/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-java/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-kotlin/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-objc/archive/refs/heads/master.zip
https://github.com/alex-pinkus/tree-sitter-swift/archive/refs/heads/main.zip
https://github.com/tree-sitter/tree-sitter-go/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-haskell/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-javascript/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-typescript/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-html/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-css/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-scss/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-regex/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-php/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-python/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-matlab/archive/refs/heads/master.zip
# https://github.com/mstanciu552/tree-sitter-matlab/archive/refs/heads/master.zip
https://github.com/r-lib/tree-sitter-r/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-julia/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-ruby/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-rust/archive/refs/heads/master.zip
https://github.com/tree-sitter/tree-sitter-scala/archive/refs/heads/master.zip
# shells, tools
https://github.com/tree-sitter/tree-sitter-bash/archive/refs/heads/master.zip
https://github.com/airbus-cert/tree-sitter-powershell/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-make/archive/refs/heads/main.zip
https://github.com/tree-sitter-grammars/tree-sitter-diff/archive/refs/heads/main.zip
https://github.com/tree-sitter-grammars/tree-sitter-bicep/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-puppet/archive/refs/heads/master.zip
# serialization formats
https://github.com/tree-sitter/tree-sitter-json/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-yaml/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-xml/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-csv/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-toml/archive/refs/heads/master.zip
https://github.com/tree-sitter-grammars/tree-sitter-thrift/archive/refs/heads/main.zip
https://github.com/tree-sitter-grammars/tree-sitter-capnp/archive/refs/heads/master.zip"

export URLS_BINDINGS=\
"
https://github.com/tree-sitter/csharp-tree-sitter/archive/refs/heads/main.zip
https://github.com/zabbius/dotnet-tree-sitter/archive/refs/heads/main.zip
"

export URL_GITHUB_SUFFIX_ZIP=


# git clone \
#     --recursive \
#         https://github.com/tree-sitter/tree-sitter-c-sharp.git \
#         externals/native/grammars/c-sharp/



IFS=$'\n'
# ZSH does not split words by default (like other shells):
setopt sh_word_split

export FOLDER=./externals/native/core/
export URL=https://github.com/tree-sitter/tree-sitter/archive/refs/heads/master.zip

rm -fr  $FOLDER
mkdir -p $FOLDER

curl \
    -v -L -C - \
    --output-dir $FOLDER/ \
    -O $URL

export TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
mv $FOLDER/master.zip $FOLDER/master.$TIMESTAMP.zip

unzip \
    $FOLDER/master.$TIMESTAMP.zip \
    -d $FOLDER/

export FOLDER=./externals/native/grammars/
rm -fr  $FOLDER
mkdir -p $FOLDER

for URL in $URLS_CORE_N_GRAMMARS
do
    if [[ $URL == "#"* ]]
    then
        continue
    fi
    echo "Downloading grammar from $URL"

    export TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    curl \
        -v -L -C - \
        --output-dir $FOLDER/ \
        -O $URL


    if [ -f $FOLDER/split-parser.zip ]; 
    then
        mv $FOLDER/split-parser.zip $FOLDER/master.$TIMESTAMP.zip
    fi

    if [ -f $FOLDER/master.zip ]; 
    then
        mv $FOLDER/master.zip $FOLDER/master.$TIMESTAMP.zip
    fi

    if [ -f $FOLDER/main.zip ]; then
        mv $FOLDER/main.zip $FOLDER/master.$TIMESTAMP.zip
    fi

    unzip \
        $FOLDER/master.$TIMESTAMP.zip \
        -d $FOLDER/

done

rm -fr $FOLDER/*.zip


export FOLDER=./externals/native/bindings/
rm -fr  $FOLDER
mkdir -p $FOLDER

for URL in $URLS_BINDINGS
do
    if [[ $URL == "#"* ]]
    then
        continue
    fi
    echo "Downloading grammar from $URL"

    export TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

    curl \
        -v -L -C - \
        --output-dir $FOLDER/ \
        -O $URL

    if [ -f $FOLDER/master.zip ]; then
        mv $FOLDER/master.zip $FOLDER/master.$TIMESTAMP.zip
    fi

    if [ -f $FOLDER/main.zip ]; then
        mv $FOLDER/main.zip $FOLDER/master.$TIMESTAMP.zip
    fi

    unzip \
        $FOLDER/master.$TIMESTAMP.zip \
        -d $FOLDER/

done

rm -fr $FOLDER/*.zip



