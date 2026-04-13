import json
from datetime import datetime
from pathlib import Path


STATE_PATH = Path(__file__).resolve().parent / ".research_reminder_state.json"
SLOTS = [8, 13, 19]


def load_state():
    if not STATE_PATH.exists():
        return {}
    try:
        return json.loads(STATE_PATH.read_text(encoding="utf-8"))
    except Exception:
        return {}


def save_state(state):
    STATE_PATH.write_text(json.dumps(state, ensure_ascii=True, indent=2), encoding="utf-8")


def current_slot(now: datetime):
    hour = now.hour
    slot = None
    for candidate in SLOTS:
        if hour >= candidate:
            slot = candidate
    return slot


def main():
    now = datetime.now()
    slot = current_slot(now)
    if slot is None:
        print(json.dumps({"continue": True}))
        return

    state = load_state()
    today = now.strftime("%Y-%m-%d")
    last_key = f"{today}:{slot}"
    if state.get("lastReminder") == last_key:
        print(json.dumps({"continue": True}))
        return

    state["lastReminder"] = last_key
    save_state(state)
    print(json.dumps({
        "continue": True,
        "systemMessage": f"Rappel planifie: lancer research-scout pour le slot de {slot:02d}h si une veille addon ou API est utile aujourd'hui."
    }))


if __name__ == "__main__":
    main()