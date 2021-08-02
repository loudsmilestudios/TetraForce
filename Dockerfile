FROM centos:centos8

RUN yum install -y wget unzip libXcursor openssl openssl-libs libXinerama libXrandr-devel libXi alsa-lib pulseaudio-libs mesa-libGL

ENV GODOT_VERSION "3.3.2"

# Install Godot Server
RUN wget -q https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip \
    && unzip Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip \
    && mv Godot_v${GODOT_VERSION}-stable_linux_headless.64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot

# Create Runtime User
RUN useradd -d /tetra tetra


# Add pck file
ADD build/TetraForce.pck /tetra/TetraForce.pck

CMD /usr/local/bin/godot --main-pack /tetra/TetraForce.pck --empty-server-timeout=900
