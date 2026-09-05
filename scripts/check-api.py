#!/usr/bin/env python3
"""Compare compiler-exported Swift declarations with the reviewed API baseline."""
import argparse
import difflib
import json
from pathlib import Path
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--update', action='store_true', help='Replace the baseline after reviewing an intentional API change.')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
result = subprocess.run([
    'swift', 'package', '--disable-sandbox', '--cache-path', str(Path(tempfile.gettempdir()) / 'parseapi-swift-api-cache'),
    'dump-symbol-graph', '--minimum-access-level', 'public', '--skip-synthesized-members',
], cwd=root, capture_output=True, text=True)
if result.returncode:
    print(result.stdout + result.stderr, file=sys.stderr)
    raise SystemExit(result.returncode)
graphs = list((root / '.build').glob('*/symbolgraph/ParseAPI.symbols.json'))
if not graphs:
    raise SystemExit('Swift did not produce the ParseAPI symbol graph.')
graph = json.loads(max(graphs, key=lambda path: path.stat().st_mtime).read_text())
names = {symbol['identifier']['precise']: '.'.join(symbol['pathComponents']) for symbol in graph['symbols']}
lines = set()
for symbol in graph['symbols']:
    declaration = ''.join(fragment['spelling'] for fragment in symbol.get('declarationFragments', []))
    lines.add(names[symbol['identifier']['precise']] + ': ' + declaration)
for relation in graph['relationships']:
    if relation['kind'] in ('conformsTo', 'inheritsFrom') and relation['source'] in names:
        target = names.get(relation['target'], relation.get('targetFallback', relation['target']))
        lines.add(names[relation['source']] + ': ' + relation['kind'] + ' ' + target)
actual = '\n'.join(sorted(lines)) + '\n'
baseline = root / 'api' / 'ParseAPI.api'
if args.update:
    baseline.parent.mkdir(exist_ok=True)
    baseline.write_text(actual)
    print('Updated Swift API baseline (' + str(len(lines)) + ' exported declarations and conformances).')
elif not baseline.exists():
    raise SystemExit('Missing API baseline. Review the exported API and run scripts/check-api.py --update.')
elif baseline.read_text() != actual:
    print(''.join(difflib.unified_diff(baseline.read_text().splitlines(True), actual.splitlines(True), fromfile='reviewed API', tofile='current API')))
    raise SystemExit('Swift API changed. Review the diff before updating the baseline.')
else:
    print('Swift API matches the reviewed baseline (' + str(len(lines)) + ' entries).')
