from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = ROOT / "docs" / "functions"
SOURCE_DIRS = ["bootstrap", "core", "ui", "locale"]

FUNC_RE = re.compile(r"^(?P<indent>\s*)(?:(?P<local>local)\s+)?function\s+(?P<name>[A-Za-z0-9_\.:]+)\s*\((?P<args>[^)]*)\)")


def extract_leading_comment(lines, index):
    comments = []
    current = index - 1
    while current >= 0:
        raw_line = lines[current]
        stripped = raw_line.strip()
        if not stripped:
            if comments:
                break
            current -= 1
            continue
        if stripped.startswith("--"):
            comment_text = stripped[2:].strip()
            if comment_text.startswith("-"):
                comment_text = comment_text[1:].strip()
            if comment_text and set(comment_text) != {"-"}:
                comments.append(comment_text)
            current -= 1
            continue
        break
    comments.reverse()
    return " ".join(part for part in comments if part)


def collect_functions(text: str):
    lines = text.splitlines()
    matches = []
    for line_number, line in enumerate(lines, start=1):
        match = FUNC_RE.match(line)
        if match:
            matches.append(
                {
                    "line": line_number,
                    "name": match.group("name"),
                    "args": match.group("args").strip(),
                    "scope": "local" if match.group("local") else "global",
                    "comment": extract_leading_comment(lines, line_number - 1),
                }
            )
    return matches


def summarize_file(relative_path: Path, functions):
    folder = relative_path.parts[0]
    lines = [f"# {relative_path.as_posix()}", "", "## Resume", ""]
    if folder == "bootstrap":
        lines.append("Point d'entree addon, initialisation, evenements et commandes slash.")
    elif folder == "core":
        lines.append("Logique metier, protocole, etat et resolution hors widgets.")
    elif folder == "ui":
        lines.append("Construction des widgets, orchestration des popups et liaison avec l'etat addon.")
    else:
        lines.append("Localisation et textes utilitaires exposes au reste de l'addon.")

    lines.extend(["", "## Fonctions", ""])
    if not functions:
        lines.append("Aucune fonction detectee.")
        return "\n".join(lines) + "\n"

    for item in functions:
        signature = f"{item['name']}({item['args']})" if item["args"] else f"{item['name']}()"
        lines.append(f"### {signature}")
        lines.append("")
        lines.append(f"- Portee: {item['scope']}")
        lines.append(f"- Ligne source: {item['line']}")
        if item["comment"]:
            lines.append(f"- Commentaire source: {item['comment']}")
        else:
            lines.append(f"- Role: fonction referencee automatiquement depuis {relative_path.as_posix()}.")
        lines.append("")

    return "\n".join(lines) + "\n"


def build_index(entries):
    lines = [
        "# Reference des fonctions EasySanalune",
        "",
        "Documentation generee automatiquement a partir des fichiers Lua addon.",
        "",
        "## Portee",
        "",
        "- Inclut `bootstrap/`, `core/`, `ui/` et `locale/`.",
        "- Exclut les dependances tierces de `libs/`.",
        "",
        "## Fichiers documentes",
        "",
    ]
    for relative_path, count in entries:
        target = relative_path.with_suffix(".md").as_posix()
        lines.append(f"- [{relative_path.as_posix()}]({target}) : {count} fonction(s)")
    lines.append("")
    lines.append("## Regeneration")
    lines.append("")
    lines.append("`C:\\Users\\loicf\\AppData\\Local\\Python\\pythoncore-3.14-64\\python.exe docs/functions/generate_function_docs.py`")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    entries = []

    for folder_name in SOURCE_DIRS:
        for source_path in sorted((ROOT / folder_name).glob("*.lua")):
            text = source_path.read_text(encoding="utf-8")
            functions = collect_functions(text)
            relative_path = source_path.relative_to(ROOT)
            output_path = OUTPUT_DIR / relative_path.with_suffix(".md")
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(summarize_file(relative_path, functions), encoding="utf-8")
            entries.append((relative_path, len(functions)))

    (OUTPUT_DIR / "README.md").write_text(build_index(entries), encoding="utf-8")


if __name__ == "__main__":
    main()