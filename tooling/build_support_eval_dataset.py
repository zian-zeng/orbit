from __future__ import annotations

import csv
import json
from collections import defaultdict
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
WORKSPACE_ROOT = REPO_ROOT.parent
SOURCE_DATASET = WORKSPACE_ROOT / "data" / "umd_student_support_dataset.csv"
OUTPUT_PATH = REPO_ROOT / "test" / "fixtures" / "support_intelligence_eval_dataset.json"

PRIMARY_LABEL_MAP = {
    "academic_support": "study_help",
    "scheduling_support": "planning",
    "stress_management": "wellbeing_checkin",
    "mental_health_support": "wellbeing_checkin",
    "disability_support": "wellbeing_checkin",
    "career_support": "writing",
    "financial_support": "summarization",
    "first_gen_support": "summarization",
    "international_support": "summarization",
    "incoming_student_navigation": "image_analysis",
    "life_admin_support": "image_analysis",
}

SECONDARY_LABEL_MAP = {
    "academic_support": "planning",
    "scheduling_support": "study_help",
    "stress_management": "planning",
    "mental_health_support": "summarization",
    "disability_support": "study_help",
    "career_support": "planning",
    "financial_support": "planning",
    "first_gen_support": "planning",
    "international_support": "planning",
    "incoming_student_navigation": "summarization",
    "life_admin_support": "planning",
}

TARGET_COUNTS = {
    "planning": 8,
    "study_help": 8,
    "wellbeing_checkin": 8,
    "writing": 6,
    "summarization": 6,
    "image_analysis": 4,
}

TOOL_MAP = {
    "planning": "schedule_builder",
    "study_help": "concept_breakdown",
    "wellbeing_checkin": "recovery_planner",
    "writing": "drafting_assistant",
    "summarization": "summary_builder",
    "image_analysis": "visual_explainer",
}

QUESTION_KEYWORD = {
    "planning": "deadline",
    "study_help": "course",
    "wellbeing_checkin": "overwhelming",
    "writing": "draft",
    "summarization": "takeaways",
    "image_analysis": "screenshot",
}


def expected_stress_band(row: dict[str, str]) -> str:
    peak = max(
        int(row["transition_stress_score"]),
        int(row["scheduling_overwhelm_score"]),
        int(row["academic_support_need_score"]),
    )
    primary = row["primary_label"]
    if primary in {"stress_management", "mental_health_support", "disability_support"} or peak >= 8:
        return "high"
    if peak >= 5:
        return "elevated"
    return "steady"


def imported_sources(row: dict[str, str], mapped_primary: str) -> list[str]:
    sources: list[str] = []
    if row.get("uses_testudo") == "yes" or row.get("aware_of_umd_calendar") == "yes":
        sources.append("Google Calendar")
    if mapped_primary in {"planning", "study_help", "writing"}:
        sources.append("Canvas")
    return list(dict.fromkeys(sources))


def template_for_label(label: str) -> str:
    return {
        "planning": "template.plan_next_steps",
        "study_help": "template.study_coach",
        "wellbeing_checkin": "template.wellbeing_checkin",
        "writing": "template.draft_polished_reply",
        "summarization": "template.summarize_clearly",
        "image_analysis": "template.analyze_image",
    }[label]


def make_history(row: dict[str, str], mapped_primary: str, mapped_secondary: str) -> list[dict[str, object]]:
    prompt = row["short_answer_goal"].strip()
    problem = row.get("short_answer_current_problem", "").strip()
    excerpt = row.get("conversation_history_excerpt", "").strip()
    response = excerpt or row.get("notes_for_routing", "").strip() or "Support summary"

    history = [
        {
            "chat_id": f"{row['student_profile_id']}-1",
            "prompt": prompt,
            "response": response,
            "selected_label": mapped_primary,
            "template_id": template_for_label(mapped_primary),
        }
    ]
    if problem:
        history.append(
            {
                "chat_id": f"{row['student_profile_id']}-2",
                "prompt": problem,
                "response": response,
                "selected_label": mapped_secondary,
                "template_id": template_for_label(mapped_secondary),
            }
        )
    return history


def to_case(row: dict[str, str]) -> dict[str, object]:
    mapped_primary = PRIMARY_LABEL_MAP[row["primary_label"]]
    mapped_secondary = SECONDARY_LABEL_MAP[row["secondary_label"]]
    sources = imported_sources(row, mapped_primary)
    expected_tools = ["chat_history_lookup", "stress_report_summarizer", TOOL_MAP[mapped_primary]]
    if "Google Calendar" in sources:
        expected_tools.append("calendar_signal_review")
    if "Canvas" in sources:
        expected_tools.append("canvas_course_scan")

    return {
        "user_id": row["student_profile_id"],
        "display_name": row["student_profile_id"].replace("UMD_SYN_", "Student "),
        "routing_label_keys": [mapped_primary, mapped_secondary],
        "recent_label_keys": [mapped_primary, mapped_secondary],
        "label_signal_sources": sources,
        "history": make_history(row, mapped_primary, mapped_secondary),
        "expected_primary_label": mapped_primary,
        "expected_stress_band": expected_stress_band(row),
        "expected_tool_ids": expected_tools,
        "expected_prompt_keyword": QUESTION_KEYWORD[mapped_primary],
        "source_profile_id": row["student_profile_id"],
    }


def main() -> None:
    with SOURCE_DATASET.open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))

    buckets: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in rows:
        mapped = PRIMARY_LABEL_MAP.get(row["primary_label"])
        if mapped is None:
            continue
        buckets[mapped].append(row)

    selected: list[dict[str, str]] = []
    for label, target in TARGET_COUNTS.items():
        selected.extend(buckets[label][:target])

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = [to_case(row) for row in selected]
    OUTPUT_PATH.write_text(json.dumps(payload, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
