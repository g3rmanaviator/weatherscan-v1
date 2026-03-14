#!/bin/sh
set -e

CONFIG_FILE="./main/configs/yourConfig.json"
TVPROVIDERS_DIR="/app/main/images/tvproviders"
TVPROVIDERS_DEFAULTS="/app/main/images/tvproviders-defaults"

# ── Seed provider images on first run ────────────────────────────────────────
# If the mounted tvproviders directory is empty (or doesn't exist yet), copy
# the default images from the sidecar baked into the image at build time.
# Files that already exist on the host are never overwritten, so custom logos
# added by the user survive container updates safely.
if [ -d "$TVPROVIDERS_DIR" ]; then
  IMAGE_COUNT=$(find "$TVPROVIDERS_DIR" -maxdepth 1 -type f | wc -l)
else
  IMAGE_COUNT=0
fi

if [ "$IMAGE_COUNT" -eq 0 ]; then
  echo "Provider images folder is empty — seeding with defaults..."
  mkdir -p "$TVPROVIDERS_DIR"
  cp "$TVPROVIDERS_DEFAULTS"/. "$TVPROVIDERS_DIR"/ 2>/dev/null || \
  cp -r "$TVPROVIDERS_DEFAULTS/." "$TVPROVIDERS_DIR/"
  echo "Seeded $(find "$TVPROVIDERS_DIR" -maxdepth 1 -type f | wc -l) provider image(s)."
else
  echo "Provider images folder already populated ($IMAGE_COUNT file(s)) — skipping seed."
  # Still copy any new defaults that don't yet exist on the host (added by upstream).
  for src in "$TVPROVIDERS_DEFAULTS"/*; do
    [ -f "$src" ] || continue
    dest="$TVPROVIDERS_DIR/$(basename "$src")"
    if [ ! -f "$dest" ]; then
      cp "$src" "$dest"
      echo "  Added new default image: $(basename "$src")"
    fi
  done
fi

# ── Patch config from environment variables ───────────────────────────────────
echo "Patching config from environment variables..."

node - <<JSEOF
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('${CONFIG_FILE}', 'utf8'));

const keys   = config.jsonSystemSettings.apiKeys;
const appear = config.jsonSystemSettings.appearanceSettings;
const audio  = config.jsonSystemSettings.audioSettings;

// ── API Keys ──────────────────────────────────────────────────────────────────
if (process.env.WEATHERDOTCOM_API_KEY) keys.api_key  = process.env.WEATHERDOTCOM_API_KEY;
if (process.env.MAPBOX_API_KEY)        keys.map_key  = process.env.MAPBOX_API_KEY;
if (process.env.TOMTOM_API_KEY)        keys.traf_key = process.env.TOMTOM_API_KEY;
if (process.env.HERE_API_KEY)          keys.HERE_key = process.env.HERE_API_KEY;

// ── Appearance ────────────────────────────────────────────────────────────────
// PROVIDER_NAME  → "Mist Digital Cable", "Berry Aviation", etc.
if (process.env.PROVIDER_NAME)
  appear.providerName = process.env.PROVIDER_NAME;

// STARTUP_TIME   → milliseconds (e.g. 15000). Must be a valid integer.
if (process.env.STARTUP_TIME) {
  const t = parseInt(process.env.STARTUP_TIME, 10);
  if (!isNaN(t)) appear.startupTime = t;
}

// PROVIDER_IMAGE → filename without extension, must exist in
//                  /app/main/images/tvproviders/ (e.g. "mistdc", "mylogo")
if (process.env.PROVIDER_IMAGE)
  appear.providerImage = process.env.PROVIDER_IMAGE;

// ── Audio ─────────────────────────────────────────────────────────────────────
// ENABLE_MUSIC   → "true" | "false"
if (process.env.ENABLE_MUSIC !== undefined && process.env.ENABLE_MUSIC !== '')
  audio.enableMusic = process.env.ENABLE_MUSIC.toLowerCase() === 'true';

// NARRATIONS     → "true" | "false"
if (process.env.NARRATIONS !== undefined && process.env.NARRATIONS !== '')
  audio.narrations = process.env.NARRATIONS.toLowerCase() === 'true';

// ── Package Settings ──────────────────────────────────────────────────────────
// PACKAGE_SETTINGS → comma-separated list, e.g.:
//   "forecast,health,traffic,travel,airport,extralocal,minicoreone,garden,ski,international"
// Omitting a package removes that segment from the rotation entirely.
if (process.env.PACKAGE_SETTINGS)
  config.jsonSystemSettings.packageSettings =
    process.env.PACKAGE_SETTINGS.split(',').map(s => s.trim()).filter(Boolean);

fs.writeFileSync('${CONFIG_FILE}', JSON.stringify(config, null, 4));
console.log('Config patched successfully.');
JSEOF

exec "$@"
