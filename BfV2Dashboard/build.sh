#!/bin/bash
cd "$(dirname "$0")"
cat *.as > ~/BfV2Dashboard.as
echo "Built ~/BfV2Dashboard.as ($(wc -l < ~/BfV2Dashboard.as) lines)"
