import argparse
import json
import re
import sys
from typing import Iterable, List, Tuple


BAD_PATTERNS: List[Tuple[str, int]] = [
    (r"\bsynergie\b", 2),
    (r"\bholistique\b", 3),
    (r"\bparadigme\b", 3),
    (r"\boptimiser(?:a|ons|ez|er)?\s+l'?experience\b", 4),
    (r"\bdans\s+une\s+logique\s+de\b", 3),
    (r"\bafin\s+de\s+repondre\s+a\s+vos\s+besoins\b", 5),
    (r"\bnous\s+allons\s+venir\b", 4),
    (r"\bforce\s+de\s+proposition\b", 4),
    (r"\ble\s+cas\s+echeant\b", 2),
    (r"\bil\s+convient\s+de\b", 2),
    (r"\bdans\s+le\s+cadre\s+de\b", 2),
    (r"\bbonnes\s+pratiques\b", 1),
    (r"\bprenez\s+en\s+compte\b", 1),
    (r"\bworkflow\s+robuste\b", 3),
    (r"\bsolution\s+elegante\b", 2),
    (r"\bexperience\s+utilisateur\b", 1),
]

FILLER_PATTERNS: List[Tuple[str, int]] = [
    (r"\bil\s+est\s+important\s+de\s+noter\s+que\b", 2),
    (r"\ben\s+d'autres\s+termes\b", 1),
    (r"\bde\s+maniere\s+generale\b", 1),
    (r"\bdans\s+ce\s+contexte\b", 1),
    (r"\bglobalement\b", 1),
]


def score_text(text: str) -> Tuple[int, List[str]]:
    score = 0
    reasons: List[str] = []
    lowered = text.lower()
    for pattern, weight in BAD_PATTERNS + FILLER_PATTERNS:
        if re.search(pattern, lowered):
            score += weight
            reasons.append(pattern)

    long_sentences = [segment.strip() for segment in re.split(r"[.!?]\s+", text) if segment.strip()]
    too_long = [segment for segment in long_sentences if len(segment) > 220]
    if too_long:
      score += min(len(too_long), 3)
      reasons.append("phrase_trop_longue")

    exclamation_count = text.count("!")
    if exclamation_count >= 3:
        score += 1
        reasons.append("excitation_excessive")

    return score, reasons


def flatten_strings(value) -> Iterable[str]:
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


def run_hook_mode() -> int:
    try:
        payload = json.load(sys.stdin)
    except Exception:
        payload = {}

    text_parts = list(flatten_strings(payload))
    combined = "\n".join(part for part in text_parts if len(part.strip()) >= 20)
    if not combined:
        print(json.dumps({"continue": True}))
        return 0

    score, reasons = score_text(combined)
    if score >= 6:
        print(json.dumps({
            "continue": True,
            "systemMessage": "Style detecte comme trop corporate ou robotique. Reviens a un francais direct et concret.",
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": "; ".join(reasons[:5])
            }
        }))
        return 0

    print(json.dumps({"continue": True}))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Detecte un style francais trop robotique ou corporate.")
    parser.add_argument("--hook", action="store_true", help="Mode hook Copilot")
    parser.add_argument("--text", default="", help="Texte a analyser")
    parser.add_argument("paths", nargs="*", help="Fichiers texte a analyser")
    args = parser.parse_args()

    if args.hook:
        return run_hook_mode()

    chunks: List[str] = []
    if args.text:
        chunks.append(args.text)
    for path in args.paths:
        try:
            with open(path, "r", encoding="utf-8") as handle:
                chunks.append(handle.read())
        except OSError as exc:
            print(f"ERREUR {path}: {exc}", file=sys.stderr)
            return 2

    if not chunks:
        print("Aucun texte fourni.", file=sys.stderr)
        return 2

    text = "\n".join(chunks)
    score, reasons = score_text(text)
    print(json.dumps({"score": score, "reasons": reasons}, ensure_ascii=True, indent=2))
    return 1 if score >= 6 else 0


if __name__ == "__main__":
    raise SystemExit(main())