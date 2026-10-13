#!/usr/bin/env python3
"""Export only this project's authentic Codex conversation/tool records, with redaction."""
import argparse
import json
import re
from pathlib import Path
from datetime import datetime, timezone
from privacy import redact as redact_data

parser = argparse.ArgumentParser()
parser.add_argument('session_file', nargs='+', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
account_home = str(Path.home())
account_name = Path.home().name


def redact(value):
    return redact_data(value, root)


records = []
models = set()
for line in (line for path in args.session_file for line in path.read_text().splitlines()):
    record = json.loads(line)
    if record.get('type') == 'turn_context':
        models.add(record.get('payload', {}).get('model', 'unknown'))
    if record.get('type') != 'response_item':
        continue
    item = record.get('payload', {})
    if item.get('type') == 'message':
        if item.get('role') not in ('user', 'assistant') or item.get('channel') == 'analysis':
            continue
    elif item.get('type') not in ('function_call', 'function_call_output', 'custom_tool_call', 'custom_tool_call_output'):
        continue
    records.append(redact(record))
output = root / 'ai-logs/codex-session.sanitized.jsonl'
output.write_text('\n'.join(json.dumps(r, ensure_ascii=False) for r in records) + '\n')
text = output.read_text()
if account_home in text or account_name in text or re.search(r'gsk_[A-Za-z0-9_-]{16,}', text):
    output.unlink()
    raise SystemExit('Export failed the privacy check.')
(root / 'ai-logs/export-info.json').write_text(json.dumps({
    'exported_at': datetime.now(timezone.utc).isoformat(),
    'source': 'Native Codex session JSONL for this task only',
    'records': len(records),
    'models': sorted(models),
    'included': 'User/assistant visible messages and tool calls/results',
    'excluded': 'Internal reasoning, system/developer messages, environment metadata and usage telemetry',
    'redacted': 'Home/project paths, account name, email addresses, credential patterns and image base64'
}, ensure_ascii=False, indent=2) + '\n')
print(f'Exported {len(records)} sanitized conversation/tool records.')
