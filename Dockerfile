# Start from the code-server Debian base image
FROM codercom/code-server:4.0.2

USER coder

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Use bash shell
ENV SHELL=/bin/bash

# Install unzip + rclone (support for remote filesystem)
RUN sudo apt-get update && sudo apt-get install unzip -y
RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local

# You can add custom software and dependencies for your environment below
# -----------

# Install a VS Code extension:
# Note: we use a different marketplace than VS Code. See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
# RUN code-server --install-extension esbenp.prettier-vscode

# Install apt packages:
# RUN sudo apt-get install -y ubuntu-make

# Copy files: 
# COPY deploy-container/myTool /home/coder/myTool

# -----------
# Create GAMA workspace
RUN mkdir -p /opt/gama-platform
RUN cd /opt/gama-platform

# Install GAMA v1.9.0 w/o JDK
RUN curl -o gama.zip -fSL $(curl -s https://api.github.com/repos/gama-platform/gama/releases/tags/1.9.0 | grep "1.9.0/GAMA.*Linux.*.zip" | cut -d ':' -f 2,3 | tr -d \") && \
	unzip gama.zip -d /opt/gama-platform

# Set absolute path
RUN sed -i 's/$( dirname "${BASH_SOURCE\[0\]}" )/\/opt\/gama-platform\/headless/g' /opt/gama-platform/headless/gama-headless.sh

# Make script executable
RUN chmod +x /opt/gama-platform/Gama /opt/gama-platform/headless/gama-headless.sh

# Release image 
FROM openjdk:17-jdk-alpine
COPY --from=0 /opt/gama-platform /opt/gama-platform

RUN apk --no-cache add bash ttf-dejavu libstdc++ libc6-compat \
	&& ln -s /opt/gama-platform/headless/gama-headless.sh /usr/sbin/gama-headless

# Docker env
WORKDIR /opt/gama-platform/headless
# Port
ENV PORT=8080

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
