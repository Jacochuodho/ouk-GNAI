## Brief goal
Help contributors and AI agents quickly understand and work productively in this repository.

## What this repo contains (big picture)
- A small code folder: `code/` holds source files. Currently there is `code/first.jac`, which contains valid Python-formatted code.
- There are no build, test, or CI configuration files present in the repository root (no `package.json`, `pyproject.toml`, `requirements.txt`, `Makefile`, or `.github/workflows/*` discovered).

## Project-specific, immediately useful facts for an AI agent
- File to read first: `code/first.jac` — it defines:
  - `lovejac() -> str` which returns a simple string.
  - an executable guard: `if __name__ == "__main__":` with `print(lovejac())`.
- Note: the file extension is `.jac` but the contents are valid Python. Running and static-analysis tools treat the file content as Python code (the extension does not change runtime behavior when executed with the Python interpreter).

## How to run or validate quickly (commands an agent can run)
- Run the script (extension doesn't matter to Python):
  - `python3 code/first.jac`
- Quick syntax check without executing logic:
  - `python3 -m py_compile code/first.jac`

## Editing and change guidance for AI agents
- If editing `code/first.jac`, preserve the top-level docstring and the `if __name__ == "__main__"` guard when keeping it runnable as a script.
- If you add new files, place them under `code/` to match current layout.
- If you convert `.jac` files into `.py`, update any inter-file imports and keep one runnable entry-point (use the same `if __name__ == "__main__"` pattern).

## Patterns and conventions discovered
- Lightweight single-file scripts: current codebase uses simple, self-contained functions and a main guard. Prefer small, focused modules.
- No explicit dependency management detected. Any added dependencies should be accompanied by a `requirements.txt` or `pyproject.toml` in the repo root.

## Integration points & external dependencies
- None discovered. There are no references to external services, packages, or CI workflows in the current files.

## When making pull requests (practical checklist for an agent)
1. Run `python3 -m py_compile` on changed Python/`.jac` files to ensure no syntax errors.
2. Keep changes minimal and focused; update or add a README section if you introduce new files or change the project structure.
3. If adding dependencies, include a `requirements.txt` or `pyproject.toml` and brief install/run instructions in README.

## Useful examples from the codebase
- `code/first.jac` — small canonical example:
  - function signature: `def lovejac() -> str:`
  - main guard: `if __name__ == "__main__": print(lovejac())`

## Next steps an agent should propose or take
- Add a short `README.md` describing how to run the script and the project's intent.
- Add a minimal test harness (optional) if the project grows; place tests under `tests/` and use pytest.

If anything here is unclear or you want me to expand sections (example-driven editing rules, a proposed README, or a tiny test), tell me which part to iterate on next.
