"""Redact exported conversation data; never alter production credential source."""
import re
from pathlib import Path

ACCOUNT_HOME = str(Path.home())
ACCOUNT_NAME = Path.home().name
ALIASES = [ACCOUNT_NAME]
if len(ACCOUNT_NAME) >= 10:
    ALIASES += [ACCOUNT_NAME[:5], ACCOUNT_NAME[5:]]


def redact_text(value, project_root=None):
    if project_root:
        value = value.replace(str(project_root), '<PROJECT>')
    value = value.replace(ACCOUNT_HOME, '<HOME>')
    value = re.sub(r'\bMacBook[\w-]*\b|\b[\w.-]+\.local\b', '<DEVICE>', value, flags=re.I)
    for alias in ALIASES:
        value = re.sub(re.escape(alias), '<USER>', value, flags=re.I)
    value = re.sub(r'/Users/[^/\s"\'<>]+(?:/[^\s"\'<>]*)?', '<USER_PATH>', value)
    value = re.sub(r'[A-Z]:\\Users\\[^\s"\'<>]+', '<USER_PATH>', value, flags=re.I)
    value = re.sub(r'/(?:private/)?var/folders/[^\s"\'<>]+', '<TEMP_PATH>', value)
    value = re.sub(r'(?<!\w)(?:gsk_|sk-(?:or-v1-|proj-)?)[A-Za-z0-9_.-]{8,}', '<REDACTED_API_KEY>', value)
    value = re.sub(r'(?i)(Bearer\s+)[A-Za-z0-9_.-]{8,}', r'\1<REDACTED_TOKEN>', value)
    value = re.sub(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}', '<REDACTED_EMAIL>', value)
    value = re.sub(r'\b[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\b', '<UUID>', value, flags=re.I)
    value = re.sub(r'(private static let (?:mask|bytes):\s*\[UInt8\]\s*=\s*)\[[\d,\s]+\]', r'\1[<REDACTED_CREDENTIAL_BYTES>]', value)
    value = re.sub(r'data:image/[^;]+;base64,[A-Za-z0-9+/=]+', '<IMAGE_DATA_OMITTED>', value)
    value = re.sub(r'(?<![A-Za-z0-9+/])[A-Za-z0-9+/]{1024,}={0,2}', '<BINARY_DATA_OMITTED>', value)
    return value


def redact(value, project_root=None):
    if isinstance(value, dict):
        if value.get('type') in ('image', 'input_image', 'image_url'):
            return {'type': value['type'], 'content': '<IMAGE_DATA_OMITTED>'}
        return {k: redact(v, project_root) for k, v in value.items() if k != 'encrypted_content'}
    if isinstance(value, list):
        return [redact(v, project_root) for v in value]
    if isinstance(value, str):
        return redact_text(value, project_root)
    return value
