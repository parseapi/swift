#!/usr/bin/env python3
"""Compare compiler-exported Swift declarations with the reviewed API baseline."""
import argparse
import difflib
import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--update', action='store_true', help='Replace the baseline after reviewing an intentional API change.')
parser.add_argument('--symbol-graph', type=Path, help='Check a ParseAPI library graph exported inside a managed build lifecycle.')
parser.add_argument('--capture', type=Path, help='Save the normalized compiler export for review.')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
if args.symbol_graph:
    graph = json.loads(args.symbol_graph.read_text())
else:
    # The package-wide exporter also attempts to load generated test modules.
    # Ask the compiler for the public library target directly instead.
    with tempfile.TemporaryDirectory(prefix='parseapi-swift-symbols-') as directory:
        result = subprocess.run([
            'swift', 'build', '--disable-sandbox', '--target', 'ParseAPI',
            '-Xswiftc', '-emit-symbol-graph', '-Xswiftc', '-emit-symbol-graph-dir', '-Xswiftc', directory,
            '-Xswiftc', '-symbol-graph-minimum-access-level', '-Xswiftc', 'public',
            '-Xswiftc', '-symbol-graph-skip-synthesized-members',
        ], cwd=root, capture_output=True, text=True)
        if result.returncode:
            print(result.stdout + result.stderr, file=sys.stderr)
            raise SystemExit(result.returncode)
        graph_path = Path(directory) / 'ParseAPI.symbols.json'
        if not graph_path.is_file():
            raise SystemExit('Swift did not produce the ParseAPI library symbol graph.')
        graph = json.loads(graph_path.read_text())
if graph.get('module', {}).get('name') != 'ParseAPI' or not graph.get('symbols'):
    raise SystemExit('Expected a nonempty ParseAPI library symbol graph.')
names = {symbol['identifier']['precise']: '.'.join(symbol['pathComponents']) for symbol in graph['symbols']}
lines = set()
for symbol in graph['symbols']:
    declaration = ''.join(fragment['spelling'] for fragment in symbol.get('declarationFragments', []))
    # Compiler-emitted graphs preserve Swift 5's implicit existential spelling.
    # Module extraction prints the equivalent explicit `any` spelling instead.
    declaration = re.sub(r': (?:any )?(Encoder|Decoder)\b', r': any \1', declaration)
    lines.add(names[symbol['identifier']['precise']] + ': ' + declaration)
for relation in graph['relationships']:
    if relation['kind'] in ('conformsTo', 'inheritsFrom') and relation['source'] in names:
        target = names.get(relation['target'], relation.get('targetFallback', relation['target']))
        lines.add(names[relation['source']] + ': ' + relation['kind'] + ' ' + target)
actual = '\n'.join(sorted(lines)) + '\n'
if args.capture:
    with args.capture.open('x') as capture:
        capture.write(actual)
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
