FROM ubuntu:24.04

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates wget unzip libfontconfig1 libdbus-1-3 libxkbcommon0 libwayland-client0 libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libgl1 libasound2t64 libpulse0 \
	&& rm -rf /var/lib/apt/lists/*

ENV GODOT_VERSION=4.7.2

RUN wget -q https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
	&& unzip Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip \
	&& mv Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot \
	&& chmod +x /usr/local/bin/godot \
	&& rm Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip

# Create Runtime User
RUN useradd --create-home --home-dir /tetra tetra


# Add pck file
COPY build/TetraForce.pck /tetra/TetraForce.pck

USER tetra
WORKDIR /tetra

CMD ["/usr/local/bin/godot", "--headless", "--main-pack", "/tetra/TetraForce.pck", "--", "--dedicatedserver=true", "--empty-server-timeout=900"]
