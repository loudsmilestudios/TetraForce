FROM centos8

# Create Runtime User
RUN useradd -d /tetra tetra

# Add build
ADD build/TetraForce /tetra/TetraForce
ADD build/TetraForce.pck /tetra/TetraForce.pck

CMD ["/tetra/TetraForce"]