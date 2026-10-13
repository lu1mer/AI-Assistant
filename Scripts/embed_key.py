#!/usr/bin/env python3
"""Embed a user-supplied credential without printing or copying plaintext to the repo."""
import argparse
import getpass
import secrets
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('key_file', nargs='?', type=Path, help='Local plaintext key file; never place it inside the repository')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
if args.key_file:
    source = args.key_file.expanduser().resolve()
    if source.is_relative_to(root):
        raise SystemExit('Keep the plaintext credential outside the project.')
    key = source.read_text().strip()
else:
    key = getpass.getpass('OpenRouter API key (input hidden): ').strip()
if not key.startswith('sk-or-v1-') or len(key) < 20 or any(c.isspace() for c in key):
    raise SystemExit('The file does not contain a valid-looking OpenRouter key. Value was not printed.')
mask = secrets.token_bytes(32)
encoded = [b ^ mask[i % len(mask)] for i, b in enumerate(key.encode())]
swift = '''import Foundation

/// XOR obfuscation only: a client-bundled key can be recovered. Never log it.
enum EmbeddedCredential {
    private static let mask: [UInt8] = MASK
    private static let bytes: [UInt8] = BYTES

    static var value: String {
        guard !mask.isEmpty else { return "" }
        return String(decoding: bytes.enumerated().map { $0.element ^ mask[$0.offset % mask.count] }, as: UTF8.self)
    }
}
'''.replace('MASK', str(list(mask))).replace('BYTES', str(encoded))
(root / 'Sources/Services/AI/EmbeddedCredential.swift').write_text(swift)
print('Obfuscated credential generated. No plaintext key was written to the project.')
