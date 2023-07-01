#FROM codercom/code-server:4.14.1-ubuntu
FROM ca-code-server
#FROM ghcr.io/lrakai/ca-code-server:latest

USER coder

# Use bash shell
ENV SHELL=/bin/bash

# Install unzip + rclone (support for remote filesystem)
RUN sudo apt-get update && sudo apt-get install unzip -y
RUN curl https://rclone.org/install.sh | sudo bash

# Copy rclone tasks to /tmp, to potentially be used
COPY deploy-container/rclone-tasks.json /tmp/rclone-tasks.json

# Branding: Set custom favicon
COPY deploy-container/favicon.ico /usr/lib/code-server/src/browser/media/favicon.ico
RUN sudo cp /usr/lib/code-server/src/browser/media/favicon.ico /usr/lib/code-server/src/browser/media/favicon.svg && \
    sudo cp /usr/lib/code-server/src/browser/media/favicon.ico /usr/lib/code-server/src/browser/media/favicon-dark-support.svg && \
    sudo cp /usr/lib/code-server/src/browser/media/favicon.ico /usr/lib/code-server/lib/vscode/resources/server/favicon.ico && \
    sudo cp /usr/lib/code-server/src/browser/media/favicon.ico /usr/lib/code-server/lib/vscode/extensions/microsoft-authentication/media/favicon.ico && \
    sudo cp /usr/lib/code-server/src/browser/media/favicon.ico /usr/lib/code-server/lib/vscode/extensions/github-authentication/media/favicon.ico

# Copy in custom config (disable password authentication)
COPY deploy-container/config.yaml .config/code-server/config.yaml

# Apply VS Code settings
COPY deploy-container/settings.json .local/share/code-server/User/settings.json

# Fix permissions for code-server
RUN sudo chown -R coder:coder /home/coder/.local && \
    sudo chown -R coder:coder /home/coder/.config

# You can add custom software and dependencies for your environment below
# -----------

# Install a VS Code extension from OpenVSX Registry:
# Note: we use a different marketplace than VS Code. See https://github.com/cdr/code-server/blob/main/docs/FAQ.md#differences-compared-to-vs-code
# Use multiple --install-extension flags to install multiple extensions
RUN code-server --install-extension ms-python.python@2023.10.1

# Install a VS Code extension from a .vsix file (e.g. Highlight Line, can't be installed in Theia)
# RUN curl -sSLo /tmp/highlight-line.vsix https://gist.github.com/lrakai/413d454bebca896ab72236f906c4fb7a/raw/cliffordfajardo.highlight-line-vscode-0.0.1.vsix && \
#     code-server --install-extension /tmp/highlight-line.vsix -vvv && \
#     rm -f /tmp/highlight-line.vsix

# Install apt packages:
# RUN sudo apt-get install -y ubuntu-make

# Copy files: 
# COPY deploy-container/myTool /home/coder/myTool

# -----------

RUN sudo mkdir -p /home/project \
    && sudo chown -R coder:coder /home/project \
    && echo "PROMPT_COMMAND='history -a'" >> /home/coder/.bashrc \
    && echo "HISTFILE='/home/project/.bash_history'" >> /home/coder/.bashrc \
    && echo "PS1=\"${debian_chroot:+($debian_chroot)}\[\033[01;32m\]coder@cloudacademylabs\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ \"" >> /home/coder/.bashrc \
    && echo "if [ -e /home/project/.init.sh ]; then source /home/project/.init.sh; fi" >> /home/coder/.bashrc

# Port
ENV PORT=3000

# Use our custom entrypoint script first
COPY deploy-container/entrypoint.sh /usr/bin/deploy-container-entrypoint.sh
ENTRYPOINT ["/usr/bin/deploy-container-entrypoint.sh"]
