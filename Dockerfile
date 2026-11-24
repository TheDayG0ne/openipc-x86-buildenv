FROM debian:bookworm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends build-essential bc bzip2 ca-certificates cpio file git gzip libncurses-dev libssl-dev patch perl python3 rsync unzip wget xz-utils && rm -rf /var/lib/apt/lists/*
COPY buildroot-entrypoint.sh /usr/local/bin/buildroot-entrypoint
RUN chmod +x /usr/local/bin/buildroot-entrypoint
WORKDIR /work
ENTRYPOINT ["/usr/local/bin/buildroot-entrypoint"]
