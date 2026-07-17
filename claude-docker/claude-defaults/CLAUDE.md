# User-level rules

## ComfyUI: draft cheap, finalize once

When generating an image via the `comfyui` MCP for preview or validation purposes (a banner,
logo, icon — anything where the exact composition/style isn't locked in yet), don't jump
straight to a single full-quality render:

1. Generate 3-5 low-resolution draft variants first — fewer sampling steps and/or a smaller
   resolution than the final asset. Cheap and fast; the point is to compare directions, not
   to judge final fidelity.
2. Present the drafts (or a description of each) so the user can pick one, or ask for
   further variations.
3. Re-render only the chosen draft at full quality/resolution as the final asset.

Skip the draft round only when the user has already described the exact final image in full
detail and just wants one output, or explicitly asks for a single direct high-quality
generation.

## Always give commit text, unprompted

Whenever a turn ends with uncommitted changes in the working tree, close with a proposed
commit message — a single line, under 100 characters, no bulleted body — without waiting
to be asked. Don't commit or push without explicit confirmation; just always have the text
ready at the end of the summary.
