# Stage 1: Build vsftpd from source
FROM debian:bullseye AS builder

# Install necessary build tools and dependencies
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /vsftpd-src

# Copy source code
COPY . .

RUN sed -i 's,\r,,;s, *$,,' ./vsftpd.conf

# Build vsftpd
RUN make

# Stage 2: Create the final image
FROM debian:bullseye-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y \
    libcap2-bin \
    libssl1.1 \
    libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the compiled binary from the build stage
COPY --from=builder /vsftpd-src/vsftpd /usr/local/sbin/vsftpd

# Copy the default vsftpd config from source
COPY --from=builder /vsftpd-src/vsftpd.conf /etc/vsftpd.conf

# Expose the FTP ports
EXPOSE 20 21

# Create the FTP user
RUN useradd -m ftpuser && echo "ftpuser:password" | chpasswd

# Run vsftpd
CMD ["/usr/local/sbin/vsftpd", "/etc/vsftpd.conf"]
