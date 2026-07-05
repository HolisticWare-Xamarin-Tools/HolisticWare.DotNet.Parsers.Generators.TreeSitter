#!/bin/bash


./externals/native/build-all.sh \
            --clean

./externals/native/build-all.sh \
            --profile balanced \


./externals/native/build-all.sh \
            --clean

./externals/native/build-all.sh \
            --profile size \


./externals/native/build-all.sh \
            --clean

./externals/native/build-all.sh \
            --profile speed \


./externals/native/build-all.sh \
            --clean

./externals/native/build-all.sh \
            --profile debug \


ll $( find externals/native/out* -iname "*bash*" | grep macos/arm )
