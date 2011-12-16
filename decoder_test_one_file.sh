#!/bin/bash
# Copyright (c) 2012 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Checks that a given assembyl file is decoded identically to objdump.
#
# Usage:
#   decoder_test_one_file.sh GAS=... OBJDUMP=... DECODER=... ASMFILE=...

set -e

# Parse arguments.
eval "$@"

# Sanity check arguments.
if [[ ! -x "$GAS" || ! -x "$OBJDUMP" || ! -x "$DECODER" ]] ; then
  echo >&2 "error: GAS or OBJDUMP or DECODER incorrect"
  exit 2
fi

if [[ ! -f "$ASMFILE" ]] ; then
  echo >&2 "error: ASMFILE is not a regular file: $ASMFILE"
  exit 3
fi

readonly asmfile=$ASMFILE

# Produce an object file, disassemble it in 2 ways and compare results.
$GAS --64 "$asmfile" -o "$asmfile.o"
rm -f "$asmfile"
$DECODER "$asmfile.o" > "$asmfile.decoder"
# Take objdump output starting at line 8 to skip the unimportant header that
# is not emulated in the decoder test.
$OBJDUMP -d "$asmfile.o" |
  tail -n+8 - |
  cmp - "$asmfile.decoder"
rm -f "$asmfile.o" "$asmfile.decoder"
