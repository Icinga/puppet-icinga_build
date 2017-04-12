#!/bin/bash
# Place this in /var/lib/jenkins
#
# Generates you a YAML ready list of installed plugins
# with their concrete version
#
# To update a Puppet Hiera config with it.

set -e

JENKINS_HOME=`readlink -f "$(dirname "$0")"`
JENKINS_PLUGINS="$JENKINS_HOME/plugins"

if [ ! -d "$JENKINS_PLUGINS" ]; then
  echo "Could not find Jenkins plugins at $JENKINS_PLUGINS" >&2
  exit 1
fi

cd "$JENKINS_PLUGINS"

echo "jenkins::plugin:"

for file in $(ls); do
  test -d "$file" || continue

  echo "  $file:"

  manifest="$file/META-INF/MANIFEST.MF"
  if [ -f "$manifest" ]; then
    version=`grep Plugin-Version "$manifest" | cut -d" " -f2 | tr -d '\r'`
    if [ -n "$version" ]; then
      echo "    version: '$version'"
    else
      echo "Version not found inside $manifest" >&2
      exit 1
    fi
  else
    echo "No manifest found at $manifest" >&2
    exit 1
  fi
done
