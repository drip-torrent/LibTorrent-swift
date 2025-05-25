#!/bin/bash

set -e

echo "Installing libtorrent dependencies..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    if command -v brew &> /dev/null; then
        echo "Installing dependencies via Homebrew..."
        brew install libtorrent-rasterbar boost openssl
    else
        echo "Error: Homebrew not found. Please install Homebrew first."
        exit 1
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if command -v apt-get &> /dev/null; then
        echo "Installing dependencies via apt..."
        sudo apt-get update
        sudo apt-get install -y libtorrent-rasterbar-dev libboost-all-dev libssl-dev
    elif command -v yum &> /dev/null; then
        echo "Installing dependencies via yum..."
        sudo yum install -y libtorrent-rasterbar-devel boost-devel openssl-devel
    else
        echo "Error: No supported package manager found."
        exit 1
    fi
else
    echo "Error: Unsupported operating system."
    exit 1
fi

echo "Dependencies installed successfully!"