#!/bin/sh
set -e

CONFIG_FILE="./main/configs/yourConfig.json"

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
if (process.env.PROVIDER_NAME)
  appear.providerName = process.env.PROVIDER_NAME;

if (process.env.STARTUP_TIME) {
  const t = parseInt(process.env.STARTUP_TIME, 10);
  if (!isNaN(t)) appear.startupTime = t;
}

if (process.env.PROVIDER_IMAGE)
  appear.providerImage = process.env.PROVIDER_IMAGE;

// ── Audio ─────────────────────────────────────────────────────────────────────
if (process.env.ENABLE_MUSIC !== undefined && process.env.ENABLE_MUSIC !== '')
  audio.enableMusic = process.env.ENABLE_MUSIC.toLowerCase() === 'true';

if (process.env.NARRATIONS !== undefined && process.env.NARRATIONS !== '')
  audio.narrations = process.env.NARRATIONS.toLowerCase() === 'true';

// ── Package Settings ──────────────────────────────────────────────────────────
if (process.env.PACKAGE_SETTINGS)
  config.jsonSystemSettings.packageSettings =
    process.env.PACKAGE_SETTINGS.split(',').map(s => s.trim()).filter(Boolean);

fs.writeFileSync('${CONFIG_FILE}', JSON.stringify(config, null, 4));
console.log('Config patched successfully.');
JSEOF

exec "$@"
