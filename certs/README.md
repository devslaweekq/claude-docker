# certs/

Optional **self-signed TLS proxy** CA. Not needed for direct access or HTTP proxy (`http://USER:PASS@HOST:PORT`).

Compose mounts `./certs` → `/tmp/certs-input`. Entrypoint `update-certs.sh` (in the image) copies `*.crt` into the system store and runs `update-ca-certificates`.

```bash
cp /path/to/your-proxy.crt certs/proxy.crt # gitignored
./claude-docker/launcher                   # restart after cert change
```
