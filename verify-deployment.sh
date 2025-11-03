#!/bin/bash

# Script to verify deployment package structure

echo "Verifying deployment package structure..."

if [ ! -f deployment.zip ]; then
    echo "Error: deployment.zip not found. Create it first."
    exit 1
fi

echo "Checking package contents..."

if command -v unzip &> /dev/null; then
    echo "Using unzip to list contents:"
    unzip -l deployment.zip | grep -E "public|index.html|server.js|package.json"
    echo ""
    echo "Full structure:"
    unzip -l deployment.zip
elif command -v powershell &> /dev/null; then
    echo "Using PowerShell to check contents:"
    powershell -Command "Expand-Archive -Path deployment.zip -DestinationPath temp-verify -Force; Get-ChildItem -Recurse temp-verify | Select-Object FullName; Remove-Item -Recurse -Force temp-verify"
else
    echo "Neither unzip nor PowerShell available to verify package."
fi

