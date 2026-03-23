# Changelog

## v1.1

### Features

- Add Magisk auto-update support

### Bug Fixes

- Add shebang and quote variables in customize.sh

### CI/CD

- Add ShellCheck workflow
- Integrate git-cliff for changelog generation

### Build

- Update Makefile with setup target and zip exclusions

### Documentation

- Add CHANGELOG.md
- Update README with strace version, fix typo, modernize install instructions

### Chores

- Add pre-commit hook and .gitattributes export-ignore
- Ignore dev files in .gitignore, .gitattributes, and CI


## v1
- Initial release: strace v5.9 (ARM64, GCC10, LTO, stripped)
