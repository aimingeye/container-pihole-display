# Contributing to Pi-hole Container Installer

First off, thanks for considering contributing! This project aims to make Pi-hole installation on Raspberry Pi as easy as possible.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When you create a bug report, include as many details as possible:

- **Pi Model** (Pi Zero 2W, Pi 4, etc.)
- **Pi OS Version** (Bullseye, Bookworm, etc.)
- **Error Messages** (full output if possible)
- **Steps to Reproduce**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion:

- **Use a clear title**
- **Describe the current behavior**
- **Explain the expected behavior**
- **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Test on a real Raspberry Pi
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Development Guidelines

### Shell Scripts

- Use `#!/bin/bash` (not sh)
- Set `set -e` for error handling
- Use meaningful variable names
- Add comments for complex logic
- Test with `bash -n script.sh` for syntax
- Use shellcheck if available

### Python Scripts

- Python 3 compatible
- Follow PEP 8 style guide
- Add docstrings to functions
- Handle errors gracefully
- Test without hardware (preview mode)

### Testing

Always test on actual hardware:

- **Pi Zero 2W** (minimum spec)
- **Pi 3/4** (common models)
- Test all flags: `-y`, `-n`, `--display`
- Test update and uninstall scripts

### Documentation

- Update README.md for new features
- Add examples for new CLI flags
- Update troubleshooting section if needed
- Keep it clear and concise

## Code Style

### Bash
```bash
# Good
log_info "Starting installation"
if [ "$VAR" = "value" ]; then
    do_something
fi

# Bad
echo "Starting installation"
if [ "$VAR"=="value" ]; then do_something; fi
```

### Python
```python
# Good
def function_name(param):
    """Clear docstring explaining what this does."""
    return result

# Bad
def fn(p):
    return p
```

## Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- First line: short summary (50 chars or less)
- Reference issues and pull requests

Examples:
```
Add support for Pi 5
Fix memory leak on Pi Zero
Update README with new examples
```

## Project Structure

```
pi-hole-container/
├── install.sh          # Main installer (keep functions modular)
├── update.sh           # Update script
├── uninstall.sh        # Uninstall script
├── pihole-display.py   # Display script
├── README.md           # Main documentation
├── STATIC_IP.md        # Static IP guide
├── ROUTER_SETUP.md     # Router configuration guide
└── CONTRIBUTING.md     # This file
```

## Adding New Features

### New CLI Flag
1. Add to argument parser in `install.sh`
2. Document in `--help` output
3. Add example to README.md
4. Test in interactive and non-interactive modes

### New Display Feature
1. Modify `pihole-display.py`
2. Test without hardware (preview mode)
3. Test with actual display
4. Document configuration options

### New Router Guide
1. Add section to `ROUTER_SETUP.md`
2. Include specific steps with screenshots if possible
3. List exact menu paths
4. Test on actual hardware

## Questions?

- Open an issue for discussion
- Tag with `question` label
- We're here to help!

## Code of Conduct

Be respectful, be constructive, be excellent to each other.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!**

