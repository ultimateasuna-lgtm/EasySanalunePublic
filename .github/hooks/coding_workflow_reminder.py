import argparse
import json
import re
import sys


CODE_PATTERNS = [
    r"\bcoder\b",
    r"\bcode\b",
    r"\bfix\b",
    r"\bdebug\b",
    r"\bbug\b",
    r"\bmodifier\b",
    r"\bchange\b",
    r"\bimplement\b",
    r"\bajoute?r\b",
    r"\brefactor\b",
    r"\bfonction\b",
    r"\blua\b",
    r"\brepo\b",
    r"\baddon\b",
]

RESEARCH_PATTERNS = [
    r"\bapi\b",
    r"\bdoc\b",
    r"\bprotocole\b",
    r"\bblizzard\b",
    r"\bwow\b",
    r"\brecherche\b",
    r"\bscout\b",
    r"\bwiki\b",
]

EDIT_TOOLS = {"apply_patch", "create_file", "edit_notebook_file"}


def flatten_strings(value):
    if isinstance(value, str):
        yield value
        return
    if isinstance(value, list):
        for item in value:
            yield from flatten_strings(item)
        return
    if isinstance(value, dict):
        for item in value.values():
            yield from flatten_strings(item)


def matches_any(text, patterns):
    lowered = text.lower()
    return any(re.search(pattern, lowered) for pattern in patterns)


def user_prompt_mode(payload):
    combined = "\n".join(flatten_strings(payload))
    if not matches_any(combined, CODE_PATTERNS):
        print(json.dumps({"continue": True}))
        return 0

    message = (
        "Tache de code detectee sur le repo: pense a appliquer le workflow automatique. "
        "Si le comportement externe, une API, le protocole ou une doc sont incertains, lance research-scout avant de coder. "
        "Si une decision technique doit etre tranchee, fais ensuite research-review. "
        "Avant de terminer, mets a jour docs/memory et regenere docs/functions si des signatures Lua ont change."
    )
    if matches_any(combined, RESEARCH_PATTERNS):
        message = (
            "Tache de code avec dimension de recherche detectee: lance research-scout avant implementation, "
            "puis research-review si une decision doit etre figee. Mets ensuite a jour docs/memory et la doc de fonctions si besoin."
        )

    print(json.dumps({"continue": True, "systemMessage": message}))
    return 0


def post_tool_mode(payload):
    tool_name = str(payload.get("tool_name") or payload.get("toolName") or "")
    if tool_name not in EDIT_TOOLS:
        print(json.dumps({"continue": True}))
        return 0

    message = (
        "Des modifications repo viennent d'etre faites. Avant de conclure la tache: "
        "verifie si research-review est necessaire, mets a jour la memoire projet utile, "
        "et regenere docs/functions si les fonctions Lua ont change."
    )
    print(json.dumps({"continue": True, "systemMessage": message}))
    return 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--post-tool", action="store_true")
    args = parser.parse_args()

    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    if args.post_tool:
        return post_tool_mode(payload)
    return user_prompt_mode(payload)


if __name__ == "__main__":
    raise SystemExit(main())