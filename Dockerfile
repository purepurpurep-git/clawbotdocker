FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Locale
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
 && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Base utils + GUI + DBus + clipboard utils
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    git \
    dbus \
    dbus-x11 \
    xfce4-terminal \
    x11-utils \
    xdg-utils \
    xclip \
    xsel \
 && rm -rf /var/lib/apt/lists/*

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
 && apt-get update \
 && apt-get install -y --no-install-recommends nodejs \
 && npm install -g npm@latest \
 && rm -rf /var/lib/apt/lists/*

# OpenClaw CLI
RUN npm install -g openclaw

# Google Chrome (non-snap)
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
    | gpg --dearmor -o /usr/share/keyrings/google-linux.gpg \
 && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends google-chrome-stable \
 && rm -rf /var/lib/apt/lists/*

# Entry point
COPY entrypoint.sh /entrypoint.sh
RUN set -eux; \
    sed -i 's/\r$//' /entrypoint.sh; \
    sed -i '1s/^\xEF\xBB\xBF//' /entrypoint.sh; \
    chmod 0755 /entrypoint.sh; \
    head -n 1 /entrypoint.sh | grep -q '^#!' || (echo 'ERROR: entrypoint has no shebang' && exit 1)

WORKDIR /workspace
EXPOSE 18789
ENTRYPOINT ["/entrypoint.sh"]
