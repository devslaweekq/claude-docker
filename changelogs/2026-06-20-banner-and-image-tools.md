# 2026-06-20 — Repository banner and image tooling

## Added

### `assets/banner.png` — repository banner
AI-generated banner for the README, composed from two elements:
- Docker whale built from circuit board traces (cyan glow)
- Claude AI brain visualization (purple glow)

Generated with ComfyUI (`slaweekq/comfyui:latest`, Z-Image Turbo model) via the
`comfyui-mcp` server running in the Claude session. Text overlay applied with `jimp`.


### `Dockerfile` — jimp pre-installed globally
`jimp` added to the global npm install — pure JavaScript, no native dependencies,
no system packages required. Available in every Claude session without extra setup.

```
npm install -g … jimp
```
