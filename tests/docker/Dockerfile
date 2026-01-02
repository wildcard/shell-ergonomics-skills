FROM node:20-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    git \
    jq \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Starship (required dependency)
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create test user (non-root)
RUN useradd -m -s /bin/bash testuser
USER testuser
WORKDIR /home/testuser

# Copy plugin to test location
COPY --chown=testuser:testuser . /home/testuser/plugin

# Copy and set up test script
COPY --chown=testuser:testuser tests/docker/test-install.sh /home/testuser/test-install.sh
RUN chmod +x /home/testuser/test-install.sh

# Run verification tests
ENTRYPOINT ["/home/testuser/test-install.sh"]
