#!/bin/bash

# Substrate Development Environment Setup Script
# This script sets up the development environment for Substrate

set -e

echo "🔧 Setting up Substrate Development Environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on macOS or Linux
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

print_status "Detected OS: $MACHINE"

# Check if Rust is installed
print_status "Checking Rust installation..."
if command -v rustc &> /dev/null; then
    RUST_VERSION=$(rustc --version)
    print_success "Rust is installed: $RUST_VERSION"
else
    print_error "Rust is not installed!"
    echo "Please install Rust from: https://rustup.rs/"
    echo "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
fi

# Check if Cargo is installed
print_status "Checking Cargo installation..."
if command -v cargo &> /dev/null; then
    CARGO_VERSION=$(cargo --version)
    print_success "Cargo is installed: $CARGO_VERSION"
else
    print_error "Cargo is not installed!"
    exit 1
fi

# Update Rust to the latest stable version
print_status "Updating Rust to latest stable version..."
rustup update stable
rustup default stable

# Install required targets
print_status "Installing required Rust targets..."
rustup target add wasm32-unknown-unknown

# Install required components
print_status "Installing required Rust components..."
rustup component add rust-src

# Check if required system dependencies are installed
print_status "Checking system dependencies..."

case $MACHINE in
    Mac)
        # Check for Homebrew
        if command -v brew &> /dev/null; then
            print_success "Homebrew is installed"
            
            # Install required packages
            print_status "Installing required packages via Homebrew..."
            brew install cmake pkg-config openssl git llvm
        else
            print_warning "Homebrew is not installed. Please install it from: https://brew.sh/"
            print_warning "Then run: brew install cmake pkg-config openssl git llvm"
        fi
        ;;
    Linux)
        # Check for package managers and install dependencies
        if command -v apt-get &> /dev/null; then
            print_status "Installing dependencies via apt-get..."
            sudo apt-get update
            sudo apt-get install -y cmake pkg-config libssl-dev git build-essential clang libclang-dev curl
        elif command -v yum &> /dev/null; then
            print_status "Installing dependencies via yum..."
            sudo yum install -y cmake pkgconfig openssl-devel git gcc gcc-c++ clang-devel curl
        elif command -v pacman &> /dev/null; then
            print_status "Installing dependencies via pacman..."
            sudo pacman -S --needed cmake pkgconf openssl git base-devel clang curl
        else
            print_warning "Could not detect package manager. Please install the following manually:"
            print_warning "cmake, pkg-config, openssl-dev, git, build-essential, clang"
        fi
        ;;
    *)
        print_warning "Unknown OS. Please ensure you have the following installed:"
        print_warning "cmake, pkg-config, openssl-dev, git, build-essential, clang"
        ;;
esac

# Install useful Cargo tools
print_status "Installing useful Cargo tools..."

# Install cargo-expand for macro expansion
if ! command -v cargo-expand &> /dev/null; then
    print_status "Installing cargo-expand..."
    cargo install cargo-expand
fi

# Install cargo-audit for security auditing
if ! command -v cargo-audit &> /dev/null; then
    print_status "Installing cargo-audit..."
    cargo install cargo-audit
fi

# Install cargo-outdated for dependency checking
if ! command -v cargo-outdated &> /dev/null; then
    print_status "Installing cargo-outdated..."
    cargo install cargo-outdated
fi

# Make scripts executable
print_status "Making scripts executable..."
chmod +x scripts/*.sh

# Verify installation
print_status "Verifying installation..."
echo ""
echo "🔍 Environment Check:"
echo "  Rust: $(rustc --version)"
echo "  Cargo: $(cargo --version)"
echo "  Targets: $(rustup target list --installed | grep wasm32-unknown-unknown || echo 'Not installed')"
echo ""

print_success "Environment setup completed!"
echo ""
echo "📝 Next steps:"
echo "  1. Run './scripts/build.sh' to build the project"
echo "  2. Run './scripts/test.sh' to run tests"
echo "  3. Run './scripts/run-dev.sh' to start the development node"
echo ""
echo "🔗 Useful commands:"
echo "  ./scripts/build.sh          - Build the project"
echo "  ./scripts/test.sh           - Run all tests"
echo "  ./scripts/run-dev.sh        - Start development node"
echo "  ./scripts/benchmark.sh      - Run benchmarks"
echo ""
echo "Happy coding! 🚀"