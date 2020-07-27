FROM ubuntu:bionic

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    python \
    python-openssl \
    unzip \
    wget \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Create Runtime User
RUN useradd -d /tetra tetra

USER tetra

# Add build
ADD build/TetraForce /tetra/TetraForce
ADD build/TetraForce.pck /tetra/TetraForce.pck

CMD ["/tetra/TetraForce"]