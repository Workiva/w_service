#!/bin/bash

dartanalyzer --fatal-warnings --no-hints \
    example/http_provider/*.dart \
    lib/*.dart \
    test/*.dart \
    test/generic/*.dart \
    test/generic/interceptors/*.dart \
    test/http/*.dart