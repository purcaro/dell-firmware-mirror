# dell-firmware-mirror

Mirrors Dell firmware and driver packages from `downloads.dell.com`, then serves them via nginx for iDRAC / Lifecycle Controller clients on a local network.

## Project layout

| File | Purpose |
|---|---|
| `dellmirror.py` | Core mirror script — fetches Dell catalog XML, resolves packages, downloads concurrently with MD5 verification |
| `domirror.sh` | Convenience wrapper: runs `dellmirror.py` with a fixed server list (`R830,R720,R720xd,R740,R740xd2`) to `/home/dell/mirror` |
| `nginx.default` | Standalone nginx vhost config — listens on `10.0.100.9:80`, serves from `/home/dell/mirror` |
| `nginx.docker.conf` | nginx config baked into the Docker image — listens on port 80, serves from `/mirror` |
| `Dockerfile` | Builds `nginx:alpine` with `nginx.docker.conf` |
| `docker-compose.yml` | Runs the nginx container on host port **8080**, mounts `./mirror` read-only |
| `terraform/` | Provisions a Proxmox VM to host this service (see below) |
| `terraform/SETUP.html` | Step-by-step HTML guide for the Terraform deploy |
| `scripts/config.sh` | Shared VM connection settings sourced by all remote scripts |
| `scripts/watch-access.sh` | Stream live nginx access log from the VM |
| `scripts/watch-errors.sh` | Stream live nginx error/warn log from the VM |
| `scripts/mirror-sync.sh` | Run the firmware sync on the VM and stream output |
| `scripts/vm-status.sh` | One-shot health snapshot (Docker, services, disk, last sync) |

## Running a mirror sync

```bash
./domirror.sh
# or directly:
./dellmirror.py --server "R830,R720,R740" --destination ./mirror --remove-catalog-location
```

Key flags: `--getcatalog` (force catalog refresh), `--onlyfirmware` (BIOS/firmware only), `--threads N` (default 8).

## Docker

```bash
docker compose up -d       # build image and start nginx on :8080
docker compose logs -f     # tail access log
docker compose down
```

Mirror files must exist in `./mirror/` before starting. Rebuild after editing `nginx.docker.conf`:

```bash
docker compose restart
```

## Terraform — Proxmox VM

`terraform/` creates an Ubuntu 24.04 LTS VM on Proxmox 9 with:
- Docker (via official install script) + this repo cloned to `/opt/dell-firmware-mirror`
- A dedicated data disk mounted at `/opt/dell-firmware-mirror/mirror`
- `dell-firmware-mirror.service` — runs `docker compose up` on boot
- `dellmirror-sync.timer` — runs `domirror.sh` nightly at 02:00

### Proxmox prerequisites

1. Create an API token with VM/datastore privileges:
   ```bash
   pveum user add terraform@pam
   pveum role add TerraformRole -privs "Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt"
   pveum aclmod / -user terraform@pam -role TerraformRole
   pveum user token add terraform@pam terraform --privsep=0
   ```

2. Enable **Snippets** content type on the target datastore:
   Datacenter → Storage → `local` → Edit → Content → add **Snippets**

### Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars          # fill in proxmox_endpoint, api_token, ssh_public_key
terraform init
terraform apply
```

After boot (~2 min for cloud-init), check status:

```bash
ssh ubuntu@<VM_IP>
journalctl -u dell-firmware-mirror -f   # nginx container
journalctl -u dellmirror-sync -f         # mirror sync
```

See `terraform/SETUP.html` for a full illustrated walkthrough.

## Remote management scripts

The `scripts/` directory lets you monitor and operate the VM without SSH-ing in manually. Configure the VM address once:

```bash
# option A — gitignored local file (recommended)
echo 'VM_HOST="192.168.1.50"' > scripts/config.local.sh

# option B — edit directly
$EDITOR scripts/config.sh   # set VM_HOST (and optionally SSH_KEY)
```

| Script | Usage |
|---|---|
| `scripts/watch-access.sh` | `./scripts/watch-access.sh` — live nginx access log (Ctrl+C to stop) |
| `scripts/watch-errors.sh` | `./scripts/watch-errors.sh` — live nginx error/warn log |
| `scripts/mirror-sync.sh` | `./scripts/mirror-sync.sh [extra flags]` — run firmware sync with live output |
| `scripts/vm-status.sh` | `./scripts/vm-status.sh` — services, disk usage, last sync entries |

Pass extra flags to the sync script as needed:

```bash
./scripts/mirror-sync.sh --onlyfirmware
./scripts/mirror-sync.sh --server "R840,R940" --threads 16
```
