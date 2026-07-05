#!/bin/bash

export ROOT_FOLDER=/Users/Shared/Projects/d/hw/dotnet-tools/tree-sitter/HW.DotNet.Parsers.Generators.TreeSitter.Private


# cp -f \
#     externals/native/CMakeLists.txt \
#     docs/build/externals/native/CMakeLists.txt  \

cp -f \
    externals/native/core/tree-sitter-master/CMakeLists.txt \
    docs/build/externals/native/core/tree-sitter-master/CMakeLists.txt  \

cp -f \
    externals/native/core/tree-sitter-master/crates/xtask/src/generate.rs \
    docs/build/externals/native/core/tree-sitter-master/crates/xtask/src/generate.rs \

cp -f \
    externals/native/core/tree-sitter-master/crates/xtask/src/upgrade_wasmtime.rs \
    docs/build/externals/native/core/tree-sitter-master/crates/xtask/src/upgrade_wasmtime.rs \



cp -f \
    externals/native/grammars/tree-sitter-bash-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-bash-master/CMakeLists.txt  \

cp -f \
    externals/native/grammars/tree-sitter-bicep-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-bicep-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-c-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-c-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-c-sharp-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-c-sharp-master/CMakeLists.txt \

# cp -f \
#     externals/native/grammars/tree-sitter-capnp-master/CMakeLists.txt \
#     docs/build/externals/native/grammars/tree-sitter-capnp-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-cpp-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-cpp-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-css-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-css-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-csv-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-csv-master/CMakeLists.txt \

mkdir -p docs/build/externals/native/grammars/tree-sitter-csv-master/csv/
cp -f \
    externals/native/grammars/tree-sitter-csv-master/csv/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-csv-master/csv/CMakeLists.txt \

mkdir -p docs/build/externals/native/grammars/tree-sitter-csv-master/psv/
cp -f \
    externals/native/grammars/tree-sitter-csv-master/psv/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-csv-master/psv/CMakeLists.txt \

mkdir -p docs/build/externals/native/grammars/tree-sitter-csv-master/tsv/
cp -f \
    externals/native/grammars/tree-sitter-csv-master/tsv/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-csv-master/tsv/CMakeLists.txt \


cp -f \
    externals/native/grammars/tree-sitter-diff-main/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-diff-main/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-go-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-go-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-haskell-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-haskell-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-html-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-html-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-java-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-java-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-javascript-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-javascript-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-json-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-json-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-julia-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-julia-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-kotlin-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-kotlin-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-make-main/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-make-main/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-objc-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-objc-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-php-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-php-master/CMakeLists.txt \

# cp -f \
#     externals/native/grammars/tree-sitter-powershell-master/CMakeLists.txt \
#     docs/build/externals/native/grammars/tree-sitter-powershell-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-puppet-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-puppet-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-python-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-python-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-r-main/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-r-main/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-regex-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-regex-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-ruby-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-ruby-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-rust-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-rust-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-scala-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-scala-master/CMakeLists.txt \

# cp -f \
#     externals/native/grammars/tree-sitter-scss-master/CMakeLists.txt \
#     docs/build/externals/native/grammars/tree-sitter-scss-master/CMakeLists.txt \

# cp -f \
#     externals/native/grammars/tree-sitter-swift-master/CMakeLists.txt \
#     docs/build/externals/native/grammars/tree-sitter-swift-main/CMakeLists.txt \

# cp -f \
#     externals/native/grammars/tree-sitter-thrift-master/CMakeLists.txt \
#     docs/build/externals/native/grammars/tree-sitter-thrift-main/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-toml-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-toml-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-typescript-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-typescript-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-xml-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-xml-master/CMakeLists.txt \

cp -f \
    externals/native/grammars/tree-sitter-yaml-master/CMakeLists.txt \
    docs/build/externals/native/grammars/tree-sitter-yaml-master/CMakeLists.txt \
