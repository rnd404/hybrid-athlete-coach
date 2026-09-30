# Hybrid Athlete Coach — an LLM coaching agent on MCP

A personal project that turns Claude Desktop into a training coach for a hybrid
athlete (streetlifting + running). The agent combines **live Garmin data** with a
**structured local knowledge base** of rules, constraints and training history, and
produces block-by-block training plans.

> This repository contains the *design*: coaching rules, prompts, templates, config
> examples and small data-quality tools. It does **not** contain any personal, health
> or biometric data, and it does **not** contain the Garmin server code.

## Architecture

| Component | Role | Origin |
|---|---|---|
| Claude Desktop | MCP client + LLM | Anthropic |
| [`Taxuspt/garmin_mcp`](https://github.com/Taxuspt/garmin_mcp) | Exposes Garmin Connect data as MCP tools | Third-party, MIT — not modified, not vendored here |
| Filesystem MCP server | Gives the model scoped access to the local knowledge base | Anthropic reference server |
| `coach/` rules, prompts, templates | Coaching logic and safety rules | **This repo (my work)** |

Diagram and trust boundaries: [`docs/architecture.md`](docs/architecture.md).

## What is original here

- **Coaching knowledge base** (in Italian, the language the agent works in): general
  rules, per-exercise progression rules, technical variants, nutrition framework by day type.
- **Planning prompt** with 16 explicit rules and a fixed output format, including
  "ask precise questions if key information is missing".
- **Safety-oriented design**: a medical-constraints file that must be read before any
  planning, with rules such as *report only what the professional wrote*, *never infer
  numeric thresholds*, *when in doubt, choose caution*, *stop signals end the session*.
- **Data handling**: a session log in JSON and [`tools/audit_logs.py`](tools/audit_logs.py),
  which measures how consistent the log is (a prerequisite for using it as an evaluation dataset).

## Repository layout

```
coach/                 rules, planning prompt, nutrition framework (generalised)
coach/templates/       empty templates for the personal files + session/weekly checkpoints
examples/              synthetic sessions and an example training block (invented numbers)
config/                Claude Desktop config example (placeholders only)
tools/                 audit_logs.py, pre_push_check.sh
docs/                  architecture and trust boundaries
```

## Setup (summary)

1. Install Claude Desktop, `uv` and Node.js.
2. Authenticate the Garmin server as described in its README, using its token-based flow
   rather than putting email/password in the config. Keep the token directory **outside** any repo.
3. Copy `config/claude_desktop_config.example.json` into your Claude Desktop config; replace
   the placeholders and **pin the Garmin server to a specific commit**.
4. Create `~/training-log/`, copy `coach/` into it and fill the templates in `coach/templates/`
   (profile, medical constraints, running goal, history). Those filled files stay local.
5. Point the filesystem server at that folder only (least privilege).
6. Paste the prompt from `coach/prompt-nuova-programmazione.md` to request a new plan.

## Privacy

Health data is special-category personal data. Personal files are git-ignored and
`tools/pre_push_check.sh` blocks pushes containing personal folders, emails, phone numbers,
dates, or any pattern listed in a local-only `.sensitive-patterns` file.

## Known limitations and security notes

- The agent treats the rule and constraint files as trusted instructions. A modified file
  would change its behaviour (context poisoning / indirect prompt injection).
- The upstream Garmin server exposes a large number of tools (its README lists 96+), including
  ones that **modify** Garmin data. A coaching agent needs only a small read-only subset.
- The upstream server is run from GitHub via `uvx`; without a pinned commit this is a supply-chain risk.
- A structured threat model and reproducible attack tests are the planned next step.

## Disclaimer

Not medical or nutritional advice. The agent is not a doctor; constraints from health
professionals always take precedence.

## Development note

Built with Claude (as coach and as a development assistant). I designed the structure and
rules of the knowledge base and I can explain every part of it.

## Credits

- [Taxuspt/garmin_mcp](https://github.com/Taxuspt/garmin_mcp) (MIT) and the
  python-garminconnect library it builds on.
- Model Context Protocol reference servers by Anthropic.
