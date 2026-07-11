#!/usr/bin/env python3
"""Export Edge Trainer metrics from FIT files to CSV.

The app writes its metrics as Connect IQ developer fields; this pulls
them out of activity files so you can build spreadsheets/charts.

Usage:
    pip install fitdecode
    python3 tools/fit_report.py path/to/*.fit > report.csv

FIT files come from the watch (GARMIN/Activity/ over USB) or from
Garmin Connect (activity page -> gear icon -> "Export Original").
"""
import csv
import sys

try:
    import fitdecode
except ImportError:
    sys.exit("fitdecode is required: pip install fitdecode")

SESSION_FIELDS = ["edge_type", "max_weight", "volume", "lifts_completed",
                  "lifts_failed", "rpe", "tut", "e1rm"]


def session_row(path):
    row = {"file": path, "date": "", "lap_weights": ""}
    for f in SESSION_FIELDS:
        row[f] = ""
    lap_weights = []
    with fitdecode.FitReader(path) as fit:
        for frame in fit:
            if not isinstance(frame, fitdecode.FitDataMessage):
                continue
            if frame.name == "session":
                for field in frame.fields:
                    if field.name in SESSION_FIELDS:
                        row[field.name] = field.value
                    elif field.name == "start_time" and field.value:
                        row["date"] = field.value.isoformat()
            elif frame.name == "lap":
                for field in frame.fields:
                    if field.name == "weight":
                        lap_weights.append(field.value)
    row["lap_weights"] = " ".join(str(w) for w in lap_weights)
    return row


def main():
    paths = sys.argv[1:]
    if not paths:
        sys.exit(__doc__)
    writer = csv.DictWriter(
        sys.stdout,
        fieldnames=["file", "date"] + SESSION_FIELDS + ["lap_weights"])
    writer.writeheader()
    for path in paths:
        try:
            writer.writerow(session_row(path))
        except Exception as exc:  # noqa: BLE001 - report and continue
            print("error reading {}: {}".format(path, exc), file=sys.stderr)


if __name__ == "__main__":
    main()
