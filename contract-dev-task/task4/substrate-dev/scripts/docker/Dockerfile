# Multi-stage build for Substrate node
FROM rust:1.70 as builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    clang \
    libclang-dev \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install wasm32-unknown-unknown target
RUN rustup target add wasm32-unknown-unknown

# Set working directory
WORKDIR /substrate

# Copy source code
COPY . .

# Build the node
RUN cargo build --release

# Runtime stage
FROM ubuntu:20.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -u 1000 substrate

# Copy binary from builder stage
COPY --from=builder /substrate/target/release/node-template /usr/local/bin/substrate-node

# Set ownership
RUN chown substrate:substrate /usr/local/bin/substrate-node

# Switch to substrate user
USER substrate

# Create data directory
RUN mkdir -p /home/substrate/data

# Expose ports
EXPOSE 9944 9933 30333

# Set default command
CMD ["/usr/local/bin/substrate-node", "--dev", "--ws-external", "--rpc-external", "--rpc-cors", "all"]