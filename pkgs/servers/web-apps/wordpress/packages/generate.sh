#!/usr/bin/env bash
PLUGINS=`cat wordplress-plugins.json | jq -r '.[]' | sed -z 's/\n/,/g;s/,$/\n/'`
WP_VERSION=5.9.3 wp4nix -p $PLUGINS -pl en
rm *.log
