# ruff-flymake
An emacs flymake backend for the python linter [ruff](https://github.com/charliermarsh/ruff).

While `ruff` has a language server mode that can be used via eglot or lsp-mode,
eglot doesn't support running multiple servers at once in a single buffer. This package
runs ruff as a separate flymake backend, allowing you to use a different python
language server with eglot.

## Installation

The package is being submitted to MELPA, but for the time being, you'll need to
install manually by putting the `ruff-flymake.el` file on your load path.

## Setup

This package doesn't activate anything by default. Add it to your flymake
backends in your `init.el` (or equivalent) using:
```
(require 'ruff-flymake)
(add-hook 'python-mode-hook 'ruff-flymake-setup-backend)
```

Note that if you're using this package alongside eglot, eglot will by default
disable other flymake backends. To avoid this but still get eglot output in
your flymake diagnostics, put this in your `init.el`:
```
(add-to-list 'eglot-stay-out-of 'flymake)
(add-hook 'flymake-diagnostic-functions 'eglog-flymake-backend nil t)
```

## Configuration

ruff-flymake will attempt to find `ruff` on your exec path. If you don't have
`ruff` installed in an accessible location, or if you want to force it to use a
specific version, you can set the variable `ruff-flymake-ruff-executable` to
the full path to the ruff binary.

For example (again, in `init.el`):
```
(setq ruff-flymake-ruff-executable "/path/to/ruff")
```

To configure ruff itself, use the [standard `pyproject.toml` or `ruff.toml`
configuration files](https://beta.ruff.rs/docs/configuration/).

## License

This package is MIT-licensed. See the `LICENSE` file for details.

It's heavily based off of the example backend in the emacs documentation at
https://www.gnu.org/software/emacs/manual/html_node/flymake/An-annotated-example-backend.html
