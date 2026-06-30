#!/usr/bin/env python3
"""Lint the flutter-skills marketplace.

Runs locally (`python3 scripts/check_skills.py`) and in CI. Standard library
only — no third-party deps. Exits non-zero if any FAIL is found; warnings do
not fail the build.

Checks:
  1. Each SKILL.md has valid frontmatter with a non-empty `name` and
     `description` (name matches ^[a-z0-9][a-z0-9-]*$, description <= 1024 chars).
  2. Each SKILL.md is <= 500 lines (progressive-disclosure rule).
  3. No double-encoded UTF-8 mojibake in ANY *.md (the corruption we removed
     must never regress).
  4. No leaked tool-call scaffolding tags in ANY *.md (e.g. a stray
     `</content>` / `</invoke>` / `<parameter …>` from a bad generation).
  5. All plugin/marketplace JSON manifests parse and carry required keys.
  6. Every `reference/<file>.md` mentioned in a SKILL.md actually exists.
  7. Every SKILL.md carries exactly one `**Announce first:**` output-contract
     marker rule, byte-identical across all skills (no drift).
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Double-encoded UTF-8 signatures (e.g. "—" -> c3 a2 c2 80 c2 94). If a file
# contains these byte runs it carries the mojibake corruption.
MOJIBAKE_SIGNATURES = (b"\xc3\xa2\xc2", b"\xc3\x82\xc2")

# Leaked Claude tool-call scaffolding — these XML tags belong to a generation
# harness, never to skill markdown. We deliberately do NOT match generic XML
# (Android `<activity>`/`<data>`, iOS plist, etc.) — only the harness tokens.
STRAY_TAG_RE = re.compile(
    r"</?(?:function_calls|invoke|content)>"
    r"|<invoke\b"
    r"|</?parameter(?:\s+name=|>)"
    r"|antml:(?:invoke|parameter|function_calls)"
)

NAME_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
REFERENCE_RE = re.compile(r"reference/[\w./-]+\.md")
ANNOUNCE_RE = re.compile(r"^- \*\*Announce first:\*\* .*$", re.MULTILINE)

fails: list[str] = []
warns: list[str] = []


def fail(msg: str) -> None:
    fails.append(msg)


def warn(msg: str) -> None:
    warns.append(msg)


def rel(p: Path) -> str:
    try:
        return str(p.relative_to(ROOT))
    except ValueError:
        return str(p)


def parse_frontmatter(text: str) -> dict[str, str] | None:
    """Return a flat dict of the leading `--- ... ---` YAML block, or None."""
    if not text.startswith("---"):
        return None
    end = text.find("\n---", 3)
    if end == -1:
        return None
    block = text[3:end].strip("\n")
    data: dict[str, str] = {}
    key = None
    for line in block.splitlines():
        m = re.match(r"^([A-Za-z0-9_-]+):\s?(.*)$", line)
        if m:
            key = m.group(1)
            data[key] = m.group(2).strip()
        elif key and line.strip():
            data[key] += " " + line.strip()
    return data


def check_skill(skill: Path) -> None:
    name = rel(skill)
    raw = skill.read_bytes()
    text = raw.decode("utf-8", errors="replace")

    lines = text.count("\n") + 1
    if lines > 500:
        fail(f"{name}: {lines} lines (> 500 line cap)")

    fm = parse_frontmatter(text)
    if fm is None:
        fail(f"{name}: missing or malformed YAML frontmatter")
        return

    sk_name = fm.get("name", "").strip()
    if not sk_name:
        fail(f"{name}: frontmatter has no `name`")
    elif not NAME_RE.match(sk_name):
        fail(f"{name}: name '{sk_name}' must match ^[a-z0-9][a-z0-9-]*$")
    elif sk_name != skill.parent.name:
        warn(f"{name}: name '{sk_name}' != directory '{skill.parent.name}'")

    desc = fm.get("description", "").strip()
    if not desc:
        fail(f"{name}: frontmatter has no `description`")
    elif len(desc) > 1024:
        fail(f"{name}: description is {len(desc)} chars (> 1024)")

    # Referenced reference/*.md must exist.
    for ref in set(REFERENCE_RE.findall(text)):
        if not (skill.parent / ref).exists():
            fail(f"{name}: references missing file '{ref}'")


def check_announce_consistency(skills: list[Path]) -> None:
    """Every SKILL.md must carry exactly one canonical `**Announce first:**`
    output-contract marker rule, byte-identical across all skills. This block is
    copy-pasted into every file, so the only defense against drift is a lint."""
    variants: dict[str, list[str]] = {}
    for skill in skills:
        text = skill.read_text(encoding="utf-8", errors="replace")
        matches = ANNOUNCE_RE.findall(text)
        if not matches:
            fail(f"{rel(skill)}: missing the '**Announce first:**' marker rule")
            continue
        if len(matches) > 1:
            fail(f"{rel(skill)}: has {len(matches)} 'Announce first' lines (expect 1)")
        variants.setdefault(matches[0], []).append(rel(skill))
    if len(variants) > 1:
        detail = "\n    ".join(
            f"{len(files)}x: {line[:70]}…" for line, files in variants.items()
        )
        fail(
            "the '**Announce first:**' marker rule has drifted into "
            f"{len(variants)} variants; keep it byte-identical:\n    " + detail
        )


def check_mojibake() -> None:
    for md in sorted(ROOT.rglob("*.md")):
        if ".git" in md.parts:
            continue
        data = md.read_bytes()
        if any(sig in data for sig in MOJIBAKE_SIGNATURES):
            fail(f"{rel(md)}: contains double-encoded UTF-8 mojibake")


def check_stray_tags() -> None:
    for md in sorted(ROOT.rglob("*.md")):
        if ".git" in md.parts:
            continue
        text = md.read_text(encoding="utf-8", errors="replace")
        for lineno, line in enumerate(text.splitlines(), 1):
            m = STRAY_TAG_RE.search(line)
            if m:
                fail(f"{rel(md)}:{lineno}: leaked tool-call tag '{m.group(0)}'")


def check_json() -> None:
    manifests = {
        ROOT / ".claude-plugin/marketplace.json": ("name", "plugins"),
        ROOT / "dart/.claude-plugin/plugin.json": ("name", "version", "description"),
        ROOT / "flutter/.claude-plugin/plugin.json": ("name", "version", "description"),
    }
    for path, required in manifests.items():
        if not path.exists():
            fail(f"{rel(path)}: manifest is missing")
            continue
        try:
            obj = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            fail(f"{rel(path)}: invalid JSON — {exc}")
            continue
        for key in required:
            if key not in obj:
                fail(f"{rel(path)}: missing required key '{key}'")


def main() -> int:
    skills = sorted(ROOT.glob("*/skills/*/SKILL.md"))
    if not skills:
        fail("no SKILL.md files found — wrong working directory?")
    for skill in skills:
        check_skill(skill)
    check_announce_consistency(skills)
    check_mojibake()
    check_stray_tags()
    check_json()

    print(f"checked {len(skills)} skills, "
          f"{len(list(ROOT.rglob('*.md')))} markdown files\n")

    for w in warns:
        print(f"  warn  {w}")
    for f in fails:
        print(f"  FAIL  {f}")

    print()
    if fails:
        print(f"✗ {len(fails)} failure(s), {len(warns)} warning(s)")
        return 1
    print(f"✓ all checks passed ({len(warns)} warning(s))")
    return 0


if __name__ == "__main__":
    sys.exit(main())
