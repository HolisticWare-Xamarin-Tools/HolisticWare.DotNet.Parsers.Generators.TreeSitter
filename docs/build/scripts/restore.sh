#!/bin/bash

export ROOT_FOLDER=

cp -f \
    docs/build/externals/native/*.sh \
    externals/native/ \

cp -f \
    docs/build/externals/native/.gitignore.bckp \
    externals/native/.gitignore \

cp -f \
    docs/build/externals/native/*.md \
    externals/native/ \


cp -f \
    docs/build/externals/native/build_helpers.cmake \
    externals/native/ \


cp -fr \
    docs/build/externals/native/wrappers/ \
    externals/native/wrappers \

cp -fr \
    docs/build/externals/native/toolchains/ \
    externals/native/toolchains \

# cp -f \
#     docs/build/externals/native/CMakeLists.txt  \
#     externals/native/CMakeLists.txt \

cp -f \
    docs/build/externals/native/core/tree-sitter-master/CMakeLists.txt  \
    externals/native/core/tree-sitter-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/core/tree-sitter-master/crates/xtask/src/generate.rs \
    externals/native/core/tree-sitter-master/crates/xtask/src/generate.rs \

cp -f \
    docs/build/externals/native/core/tree-sitter-master/crates/xtask/src/upgrade_wasmtime.rs \
    externals/native/core/tree-sitter-master/crates/xtask/src/upgrade_wasmtime.rs \










cp -f \
    docs/build/externals/native/core/tree-sitter-master/.github/workflows/build.yml \
    externals/native/core/tree-sitter-master/.github/workflows/build.yml \


cp -f \
    docs/build/externals/native/grammars/tree-sitter-bash-master/CMakeLists.txt  \
    externals/native/grammars/tree-sitter-bash-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-bicep-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-bicep-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-c-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-c-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-c-sharp-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-c-sharp-master/CMakeLists.txt \

# cp -f \
#     docs/build/externals/native/grammars/tree-sitter-capnp-master/CMakeLists.txt \
#     externals/native/grammars/tree-sitter-capnp-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-cpp-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-cpp-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-css-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-css-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-csv-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-csv-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-csv-master/csv/CMakeLists.txt \
    externals/native/grammars/tree-sitter-csv-master/csv/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-csv-master/psv/CMakeLists.txt \
    externals/native/grammars/tree-sitter-csv-master/psv/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-csv-master/tsv/CMakeLists.txt \
    externals/native/grammars/tree-sitter-csv-master/tsv/CMakeLists.txt \



cp -f \
    docs/build/externals/native/grammars/tree-sitter-diff-main/CMakeLists.txt \
    externals/native/grammars/tree-sitter-diff-main/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-go-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-go-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-haskell-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-haskell-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-html-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-html-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-java-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-java-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-javascript-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-javascript-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-json-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-json-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-julia-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-julia-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-kotlin-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-kotlin-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-make-main/CMakeLists.txt \
    externals/native/grammars/tree-sitter-make-main/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-objc-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-objc-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-php-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-php-master/CMakeLists.txt \

# cp -f \
#     docs/build/externals/native/grammars/tree-sitter-powershell-master/CMakeLists.txt \
#     externals/native/grammars/tree-sitter-powershell-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-puppet-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-puppet-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-python-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-python-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-r-main/CMakeLists.txt \
    externals/native/grammars/tree-sitter-r-main/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-regex-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-regex-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-ruby-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-ruby-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-rust-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-rust-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-scala-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-scala-master/CMakeLists.txt \

# cp -f \
#     docs/build/externals/native/grammars/tree-sitter-scss-master/CMakeLists.txt \
#     externals/native/grammars/tree-sitter-scss-master/CMakeLists.txt \

# cp -f \
#     docs/build/externals/native/grammars/tree-sitter-swift-main/CMakeLists.txt \
#     externals/native/grammars/tree-sitter-swift-master/CMakeLists.txt \

# cp -f \
#     docs/build/externals/native/grammars/tree-sitter-thrift-main/CMakeLists.txt \
#     externals/native/grammars/tree-sitter-thrift-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-toml-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-toml-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-typescript-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-typescript-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-xml-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-xml-master/CMakeLists.txt \

cp -f \
    docs/build/externals/native/grammars/tree-sitter-yaml-master/CMakeLists.txt \
    externals/native/grammars/tree-sitter-yaml-master/CMakeLists.txt \
