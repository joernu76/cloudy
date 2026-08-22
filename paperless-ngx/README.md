# Paperless-ngx

Document management with OCR, running on cloudy.

Based on the [official docker-compose.postgres.yml](https://github.com/paperless-ngx/paperless-ngx/blob/main/docker/compose/docker-compose.postgres.yml)
with bind mounts to `/var/paperless/` and tessdata_best for better OCR quality.

## Setup

1. Copy `.env.example` to `.env` and fill in the values:

   ```
   cp .env.example .env
   nano .env
   ```

   Generate the secret key with:
   ```
   python3 -c "import secrets; print(secrets.token_urlsafe(64))"
   ```

2. Download tessdata_best for higher-quality OCR (German + English):

   ```
   sudo bash setup-tessdata.sh
   ```

   This downloads ~24 MB of Tesseract "best" trained data to `/var/paperless/tessdata/`.
   The compose file mounts the individual `.traineddata` files into the container,
   replacing the default "fast" models without clobbering other tessdata files.

3. Start the stack:

   ```
   docker compose up -d
   ```

4. Open `http://cloudy:8000` and log in with the admin credentials from `.env`.

## Adding OCR languages

To add another language (e.g. French):

1. Add the download to `setup-tessdata.sh` and re-run it.
2. Add a volume mount in `docker-compose.yml`:
   ```
   - /var/paperless/tessdata/fra.traineddata:/usr/share/tesseract-ocr/5/tessdata/fra.traineddata:ro
   ```
3. Add the language code to `PAPERLESS_OCR_LANGUAGE` in `docker-compose.yml`:
   ```
   PAPERLESS_OCR_LANGUAGE=deu+eng+fra
   ```
4. `docker compose restart webserver`

## Usage

Drop files into `/var/paperless/consume/` for automatic ingestion, or upload
through the web UI.

## Data

All persistent data lives under `/var/paperless/`:

| Path | Contents |
|------|----------|
| `postgres/` | PostgreSQL database |
| `valkey/` | Valkey (broker) data |
| `data/` | Paperless internal data (search index, classification) |
| `media/` | Original and archived documents |
| `export/` | Document exporter output |
| `consume/` | Drop folder for automatic ingestion |
| `tessdata/` | Tesseract best-quality trained data |
