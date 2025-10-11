#!/bin/bash

# Substrate Development Build Script
# This script builds the Substrate node and runtime

set -e

echo "🔨 Building Substrate Development Node..."

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed. Please install Rust first."
    echo "Visit: https://rustup.rs/"
    exit 1
fi

# Check if wasm32-unknown-unknown target is installed
if ! rustup target list --installed | grep -q "wasm32-unknown-unknown"; then
    echo "📦 Installing wasm32-unknown-unknown target..."
    rustup target add wasm32-unknown-unknown
fi

# Build the project
echo "🏗️  Building the project..."
cargo build --release

echo "✅ Build completed successfully!"
echo "📍 Binary location: ./target/release/substrate-dev"

# Check if the binary was created
if [ -f "./target/release/substrate-dev" ]; then
    echo "🎉 Substrate Development Node is ready to use!"
    echo ""
    echo "To run the node:"
    echo "  ./target/release/substrate-dev --dev"
    echo ""
    echo "To run with temporary storage:"
    echo "  ./target/release/substrate-dev --dev --tmp"
else
    echo "❌ Build failed - binary not found"
    exit 1
fi