FROM node:lts-alpine

WORKDIR /app

# Copy package files first for layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm install --production

# Copy the rest of the app
COPY . .

# Blank any keys that may have been committed to the config — real keys are
# injected at runtime via docker-entrypoint.sh from environment variables
RUN node -e " \
  const fs = require('fs'); \
  const p = './main/configs/yourConfig.json'; \
  const c = JSON.parse(fs.readFileSync(p, 'utf8')); \
  const k = c.jsonSystemSettings.apiKeys; \
  k.api_key = ''; k.map_key = ''; k.traf_key = ''; k.HERE_key = ''; \
  fs.writeFileSync(p, JSON.stringify(c, null, 4)); \
  console.log('API keys blanked from image.'); \
"

# Stash a copy of the shipped provider images to a sidecar path BEFORE declaring
# the VOLUME. Once a host directory is mounted over /app/main/images/tvproviders
# at runtime, Docker hides everything that was there. The sidecar gives the
# entrypoint a source to seed the host folder from on first run.
RUN cp -r /app/main/images/tvproviders /app/main/images/tvproviders-defaults

# Copy the entrypoint script and make it executable
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 3000

# Mount point for custom provider logo images.
# Drop PNG/JPG files here and reference them by filename (no extension) via PROVIDER_IMAGE.
# On first run the entrypoint seeds this from tvproviders-defaults automatically.
VOLUME ["/app/main/images/tvproviders"]

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["npm", "start"]
