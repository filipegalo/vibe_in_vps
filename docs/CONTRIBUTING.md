# Contributing

Thank you for your interest in contributing to vibe_in_vps!

## Project Philosophy

1. **Simplicity First** - Keep it simple for beginners
2. **No Local Tools** - Everything should work via GitHub Actions
3. **Clear Documentation** - Explain every step, avoid jargon
4. **Boring Technology** - Prefer proven, stable solutions

## Development Workflow

### Quick Reference

| Script | Purpose |
|--------|---------|
| `npm start` (in app/) | Start example app locally |
| `./scripts/test-local.sh` | Test Docker build locally |
| `./scripts/validate-terraform.sh` | Validate Terraform config |
| `./scripts/destroy.sh` | Destroy infrastructure |

### Testing Locally

Before pushing changes:

```bash
# Test Docker build
./scripts/test-local.sh

# Validate Terraform
cd infra/terraform
terraform init
terraform validate
```

## Pull Request Process

1. **Fork** the repository
2. **Create** a feature branch
3. **Make** your changes
4. **Test** end-to-end if possible
5. **Update** documentation (README.md, SETUP.md, etc.)
6. **Submit** PR with clear description

### Commit Message Format

Follow conventional commits:

```
feat: add Cloudflare SSL support
fix: correct healthcheck URL in deploy workflow
docs: update SETUP.md with troubleshooting
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## Code Guidelines

### Shell Scripts

- Use `set -euo pipefail`
- Add clear comments
- Echo progress messages

### Terraform

- Use descriptive resource names
- Comment complex resources
- Use variables for all configurable values

### GitHub Actions

- Descriptive step names
- Show progress in output
- Use `if:` conditions appropriately

## What to Contribute

We especially welcome:

- Bug fixes
- Documentation improvements
- Example applications (different languages/frameworks)
- Troubleshooting guides
- Cost optimizations

## Questions?

Open a GitHub Discussion or Issue.

Thank you for helping make deployment easier for everyone! 🚀
