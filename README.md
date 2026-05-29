# dell-firmware-mirror

A multithreaded Python utility to mirror Dell firmware and driver packages from `downloads.dell.com`, paired with an nginx configuration to serve the mirror to iDRAC / Lifecycle Controller clients on a local network.

## How it works

1. `dellmirror.py` fetches Dell's master catalog (`Catalog/Catalog.xml.gz`) and parses the XML to find `SoftwareBundle` entries matching the requested server models.
2. For each matching bundle it resolves the constituent `SoftwareComponent` packages, checks whether the local copy exists and passes an MD5 checksum, and queues anything missing or changed for download.
3. Downloads run concurrently across a configurable thread pool; progress is printed with per-thread colour coding.
4. Optionally the `baseLocation` / `baseLocationAccessProtocols` attributes are stripped from the catalog so that Lifecycle Controller clients resolve component URLs against the mirror rather than `downloads.dell.com`.

## Requirements

```
pip install requests
```

Python 3.6+ standard library covers the rest (`xml.etree`, `gzip`, `hashlib`, `threading`, `queue`).

## Usage

### dellmirror.py

```
./dellmirror.py --server MODELS --destination WEBROOT [options]
```

| Flag | Required | Description |
|---|---|---|
| `--server MODELS` | yes | Comma-separated list of Dell model names to mirror, e.g. `R720,R740,R830` |
| `--destination WEBROOT` | yes | Local directory that will be (or is already) the nginx web root |
| `--getcatalog` | no | Force a fresh download of `Catalog.xml.gz` even if one already exists |
| `--remove-catalog-location` | no | Strip `baseLocation` / `baseLocationAccessProtocols` from the catalog so clients use the mirror URL |
| `--onlyfirmware` | no | Skip non-BIOS / non-firmware components (useful for Lifecycle Controller–only updates) |
| `--threads N` | no | Number of parallel download threads (default: 8) |

On first run the catalog is always downloaded. Subsequent runs skip files that already exist locally and pass their MD5 check.

### domirror.sh

Convenience wrapper that mirrors a fixed set of models to `/home/dell/mirror`:

```bash
./domirror.sh
```

Edit the model list and destination path in the script to match your environment.

## Serving the mirror

### Standalone nginx

Copy `nginx.default` to `/etc/nginx/sites-available/dell-mirror`, update the `listen` address and `root` path for your server, then enable it:

```bash
ln -s /etc/nginx/sites-available/dell-mirror /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx
```

### Docker (recommended)

See [Docker setup](#docker-setup) below.

---

## Docker setup

The Docker setup runs nginx in a container and mounts your local mirror directory read-only into the container.

### Quick start

```bash
# Build the image and start nginx
docker compose up -d

# Tail the access log
docker compose logs -f
```

By default nginx listens on port **8080** on all host interfaces and serves files from `./mirror` inside this repository directory. Change the port or mirror path in `docker-compose.yml` before starting.

### Stopping

```bash
docker compose down
```

### Customising the nginx config

Edit `nginx.docker.conf` and restart the container:

```bash
docker compose restart
```
