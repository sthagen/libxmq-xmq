#!/bin/sh
# libxmq - Copyright 2024 Fredrik Öhrström (spdx: MIT)

PROG=$1
OUTPUT=$2

if [ -z "$OUTPUT" ] || [ -z "$PROG" ]
then
    echo "Usage: tests/test_grammars.sh [XMQ_BINARY] [OUTPUT_DIR]"
    exit 1
fi

mkdir -p $OUTPUT

$PROG --ixml=grammars/core/ixml.ixml grammars/core/ixml.ixml > $OUTPUT/ixml.output 2>/dev/null
$PROG grammars/core/ixml.xml > $OUTPUT/ixml.expected 2>/dev/null
if diff $OUTPUT/ixml.output $OUTPUT/ixml.expected
then
    echo "OK: test ixml.ixml"
else
    echo "ERR: Failed to parse ixml.ixml"
    exit 1
fi
