#!/bin/sh

if [ -d "./coverage_report" ]; then
    rm -rf ./coverage_report
fi
if [ -f "./coverage.lcov" ]; then
    rm ./coverage.lcov
fi

pub get
pub run dart_codecov_generator --report-on=lib/ "$@"