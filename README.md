# weatherscan-v1

A Dockerized fork of [MistWeatherMedia/weatherscan-v1](https://github.com/MistWeatherMedia/weatherscan-v1) — Weatherscan v1 (2003–2005) simulation in HTML/JS/CSS, built for self-hosting on Unraid or any Docker host.

---

## Setup

### 1. Pre-populate the provider images folder

Run this **once** before starting the container for the first time. It downloads all default provider logo images from the upstream repo into your appdata folder:

```bash
DEST=/mnt/user/appdata/weatherscan-v1/tvproviders && \
mkdir -p "$DEST" && \
curl -s "https://api.github.com/repos/MistWeatherMedia/weatherscan-v1/contents/main/images/tvproviders" \
  | grep '"download_url"' | cut -d'"' -f4 \
  | while read url; do curl -sL -o "$DEST/$(basename "$url")" "$url" && echo "  Downloaded: $(basename "$url")"; done
```

To add your own logo, drop a PNG or JPG into the same folder and reference it by filename (without extension) via the `PROVIDER_IMAGE` variable.

To refresh the defaults after an upstream update, just re-run the command above — it will overwrite the defaults but leave any files with names not present in the upstream repo untouched.

---

### 2. Start the container

**Docker CLI:**
```bash
docker run -d \
  --name weatherscan-v1 \
  -p 3000:3000 \
  -v /mnt/user/appdata/weatherscan-v1/tvproviders:/app/main/images/tvproviders \
  -e WEATHERDOTCOM_API_KEY=your_key \
  -e MAPBOX_API_KEY=your_key \
  -e PROVIDER_NAME="My Cable Co." \
  -e PROVIDER_IMAGE=mistdc \
  ghcr.io/g3rmanaviator/weatherscan-v1:latest
```

**Unraid:** import `weatherscan-v1.xml` via Community Applications or manually via Docker → Add Container → Template.

---

## Environment Variables

### Required

| Variable | Description |
|---|---|
| `WEATHERDOTCOM_API_KEY` | weather.com (IBM Weather Company) API key |
| `MAPBOX_API_KEY` | Mapbox API key — used for radar and map layers |

### Optional — Traffic

| Variable | Description |
|---|---|
| `TOMTOM_API_KEY` | TomTom API key — needed only if `traffic` is in `PACKAGE_SETTINGS` |
| `HERE_API_KEY` | HERE.com API key — needed only if `traffic` is in `PACKAGE_SETTINGS` |

### Appearance

| Variable | Default | Description |
|---|---|---|
| `PROVIDER_NAME` | `Mist Digital Cable` | Provider name shown on screen |
| `PROVIDER_IMAGE` | `mistdc` | Logo filename (no extension) from `tvproviders/` |
| `STARTUP_TIME` | `15000` | Intro animation duration in ms. Set to `0` to skip |

### Audio

| Variable | Default | Description |
|---|---|---|
| `ENABLE_MUSIC` | `true` | Background music. `true` or `false` |
| `NARRATIONS` | `true` | Voice narrations. `true` or `false` |

### Content

| Variable | Default | Description |
|---|---|---|
| `PACKAGE_SETTINGS` | `forecast,health,traffic,travel,airport,extralocal,minicoreone,garden,ski,international` | Comma-separated list of segments to include in the rotation. Remove any entry to drop it from the loop entirely |

---

## Notes

- API keys baked into `yourConfig.json` upstream are automatically blanked during the Docker build. Real keys are injected at container startup from the environment variables above — they are never written to the image.
- The container syncs automatically from the upstream repo daily via GitHub Actions and rebuilds the image on every push to `main`.
