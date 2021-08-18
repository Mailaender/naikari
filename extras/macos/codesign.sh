#!/bin/bash

# After building Naikari.app, use this script to sign the bundle. Requires a
# single argument: the signing identity. This should be a code-signing
# certificate present in the default keychain.

# Official Naikari builds are currently not yet signed, so this script is right
# now just an example.

exec codesign --verbose --force --deep --sign "$1" \
  --entitlements extras/macos/entitlements.plist \
  Naikari.app
