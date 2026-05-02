# Native Library Fuzzing for Android RE

## Why Fuzz Native Libraries

Android apps increasingly ship with native `.so` libraries for performance, DRM, crypto,
anti-tampering, and proprietary protocols. These libraries process untrusted input from:

- Deep link URIs and Intent extras parsed in native code
- Network protocol data
- File formats (images, video, documents, custom formats)
- JNI bridge data from Java/Kotlin layer

Native code bugs (buffer overflows, use-after-free, integer overflows, format string bugs)
bypass Android's sandbox and ASLR, enabling privilege escalation, code execution, or
persistent compromise. These bugs are invisible to Java-level static analysis (Semgrep/CodeQL)
and dynamic analysis (Frida hooks on Java methods).

## When to Fuzz

Fuzz native libraries when:

- `jni/` or `lib/` directories exist in the APK
- `lib/*/lib*.so` files are present after extraction
- Strings analysis shows parsing functions (XML, JSON, protobuf, custom formats)
- Frida hooks show JNI calls passing data to native functions
- The app processes file formats or network protocols in native code
- Anti-tampering or root detection is implemented in native code (bypass via fuzzing)

## Setup

```bash
# Install AFL++
nix run nixpkgs#afl-plus-plus -- --version
# Or build from source for latest
pip install --user aflplusplus

# Install crash analysis tools
# GDB for crash context
nix run nixpkgs#gdb -- --version

# AddressSanitizer support (compile targets with -fsanitize=address)
# AFL++ QEMU mode for binary-only fuzzing (no source needed)
```

## Fuzzing Strategies

### Strategy 1: Binary-Only Fuzzing with AFL++ QEMU Mode

Use when you only have the compiled `.so` — no source code available.

```bash
# Extract native libraries from APK
cd ~/Documents/<app>/analysis/
mkdir -p native-libs
cp ~/.cache/android-re/out/<app>/extracted/lib/arm64-v8a/*.so native-libs/
cp ~/.cache/android-re/out/<app>/extracted/lib/armeabi-v7a/*.so native-libs/

# Identify target functions
strings native-libs/libtarget.so | grep -iE 'parse|decode|read|process|handle|decrypt|verify'
nm -D native-libs/libtarget.so | grep -iE 'Java_|JNI_'

# Build a harness that calls the target function
# (see Harness section below)

# Run AFL++ in QEMU mode (binary-only, no instrumentation needed)
afl-qemu-trace ./harness @@
```

### Strategy 2: Source-Available Fuzzing with AFL++

Use when you have source code (rebuilt APK, open-source library, or jadx reveals JNI source).

```bash
# Compile with AFL++ instrumentation
CC=afl-clang-fast CXX=afl-clang-fast++ make

# Or compile with AddressSanitizer for better crash detection
CC=afl-clang-fast CXX=afl-clang-fast++ \
  CFLAGS="-fsanitize=address -fno-omit-frame-pointer" \
  make

# Run fuzzer
afl-fuzz -i corpus/ -o findings/ -- ./harness @@
```

### Strategy 3: Frida-Based Fuzzing

Use when you need to fuzz in the context of the running app.

```bash
# Use Frida's fuzzing module
# Write a Frida fuzzing script that hooks JNI entry points
frida -U -f com.target.app -l fuzz_jni.js

# Example fuzz_jni.js structure:
# Java.perform(function() {
#   var targetClass = Java.use("com.target.NativeParser");
#   var parseMethod = targetClass.parseFromNative;
#   // Fuzz parseMethod with AFL-style mutation
# });
```

## Autonomous Corpus Generation

Intelligent seed generation dramatically improves fuzzing efficiency. Analyze the target binary
to understand what input formats it expects.

### Step 1: Extract Input Format Hints from Binary

```bash
# Extract strings that reveal expected input formats
strings -n 4 native-libs/libtarget.so | \
  grep -iE '<|>|xml|json|\{|}|\[|\]|http|content:|<?' | \
  sort -u > ~/Documents/<app>/analysis/native-strings-formats.txt

# Look for magic bytes and format signatures
xxd native-libs/libtarget.so | grep -E '7f45|504b|ffd8|8950|4749' | head -20

# Check for protobuf descriptors
strings native-libs/libtarget.so | grep -E '\.proto|google.protobuf'

# Check for XML parser imports
nm -D native-libs/libtarget.so | grep -iE 'xml|expat|sax'
```

### Step 2: Generate Format-Specific Seeds

Based on the format hints, generate initial corpus files:

```python
#!/usr/bin/env python3
"""Generate smart fuzzing seeds from binary string analysis."""
import json, os

STRINGS_FILE = os.path.expanduser(
    "~/Documents/<app>/analysis/native-strings-formats.txt"
)
OUTPUT_DIR = os.path.expanduser(
    "~/Documents/<app>/analysis/fuzz-corpus/"
)

os.makedirs(OUTPUT_DIR, exist_ok=True)

def detect_format(line):
    if '<' in line and '>' in line:
        return 'xml'
    if '{' in line or '":"' in line:
        return 'json'
    if line.startswith(('http://', 'https://', 'content://')):
        return 'uri'
    return None

with open(STRINGS_FILE) as f:
    for i, line in enumerate(f):
        fmt = detect_format(line.strip())
        if fmt == 'xml':
            # Generate XML seed with interesting edge cases
            seed = f'<?xml version="1.0"?><root><data>{line.strip()}</data></root>'
            with open(f'{OUTPUT_DIR}/xml_seed_{i:03d}', 'w') as out:
                out.write(seed)
        elif fmt == 'json':
            seed = json.dumps({"input": line.strip(), "extra": "A" * 256})
            with open(f'{OUTPUT_DIR}/json_seed_{i:03d}', 'w') as out:
                out.write(seed)
        elif fmt == 'uri':
            # URI with long query params and special chars
            seed = f'{line.strip()}?p1={"A"*100}&p2=%00%0d%0a'
            with open(f'{OUTPUT_DIR}/uri_seed_{i:03d}', 'w') as out:
                out.write(seed)

# Always include minimal seeds for common formats
with open(f'{OUTPUT_DIR}/empty', 'w') as f:
    pass
with open(f'{OUTPUT_DIR}/null_byte', 'wb') as f:
    f.write(b'\x00')
with open(f'{OUTPUT_DIR}/long_string', 'w') as f:
    f.write('A' * 65536)
with open(f'{OUTPUT_DIR}/format_string', 'w') as f:
    f.write('%s%s%s%s%s%n%n%n%n%n')
```

### Step 3: Goal-Directed Seeds

Generate seeds targeting specific vulnerability classes:

```python
# Buffer overflow seeds
for size in [64, 128, 256, 512, 1024, 4096, 65536]:
    with open(f'{OUTPUT_DIR}/overflow_{size}', 'w') as f:
        f.write('A' * size)

# Integer overflow seeds
for val in ['0', '-1', '2147483647', '4294967295', '-2147483648']:
    with open(f'{OUTPUT_DIR}/int_{val}', 'w') as f:
        f.write(val)

# Format string seeds
for fmt in ['%s', '%x', '%n', '%p', '%s%s%s%s', '%n%n%n%n']:
    with open(f'{OUTPUT_DIR}/fmt_{fmt.replace("%","")}', 'w') as f:
        f.write(fmt)
```

## Building a Fuzzing Harness

### C Harness for JNI Functions

```c
// harness.c — AFL++ harness for Android native library
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    // Load the target library
    void *lib = dlopen("./libtarget.so", RTLD_LAZY);
    if (!lib) {
        fprintf(stderr, "dlopen failed: %s\n", dlerror());
        return 1;
    }

    // Find the target function
    typedef int (*target_func_t)(const char *data, int len);
    target_func_t target = (target_func_t)dlsym(lib, "Java_com_target_NativeParser_parseData");
    if (!target) {
        fprintf(stderr, "dlsym failed: %s\n", dlerror());
        return 1;
    }

    // Read input from file (AFL++ provides mutated input via @@)
    FILE *f = fopen(argv[1], "rb");
    if (!f) return 1;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(len + 1);
    fread(buf, 1, len, f);
    buf[len] = '\0';
    fclose(f);

    // Call the target function
    target(buf, len);

    free(buf);
    dlclose(lib);
    return 0;
}
```

### Python Harness for Quick Testing

```python
#!/usr/bin/env python3
"""Quick native function tester — call JNI functions via ctypes."""
import ctypes, sys

lib = ctypes.CDLL("./libtarget.so")

# Define function signature
lib.Java_com_target_NativeParser_parseData.argtypes = [
    ctypes.c_char_p, ctypes.c_int
]
lib.Java_com_target_NativeParser_parseData.restype = ctypes.c_int

with open(sys.argv[1], "rb") as f:
    data = f.read()

result = lib.Java_com_target_NativeParser_parseData(data, len(data))
print(f"Result: {result}")
```

## Crash Analysis

### Crash Deduplication

AFL++ automatically deduplicates crashes, but verify:

```bash
# AFL++ stores crashes in findings/default/crashes/
ls -la findings/default/crashes/

# Each crash has an ID and a description
# Unique crashes are identified by coverage path, not just signal

# Quick triage: reproduce each crash
for crash in findings/default/crashes/id:*; do
    echo "=== $crash ==="
    ./harness "$crash" 2>&1 | head -5
done
```

### GDB Crash Context

```bash
# Debug a specific crash under GDB
gdb --args ./harness findings/default/crashes/id:000000,...

# GDB commands
# run
# bt              — backtrace
# info registers  — register state
# x/20x $sp       — stack dump
# x/s $rdi        — first argument (often the input)
# info frame      — frame info

# For ASan builds, the crash report includes:
# - Heap buffer overflow / stack buffer overflow / use-after-free
# - Source location of the allocation
# - Source location of the free (for UAF)
# - Stack trace of the access
```

### Crash Classification

Classify each crash by type and exploitability:

| Crash Type                 | Signal          | Exploitability                   |
| -------------------------- | --------------- | -------------------------------- |
| Stack buffer overflow      | SIGSEGV/SIGABRT | High — RIP control possible      |
| Heap buffer overflow       | SIGSEGV/SIGABRT | High — heap metadata corruption  |
| Use-after-free             | SIGSEGV         | High — code execution via vtable |
| Null pointer deref         | SIGSEGV         | Low — denial of service only     |
| Integer overflow           | SIGABRT         | Medium — leads to heap overflow  |
| Format string              | SIGSEGV         | High — arbitrary write           |
| Stack overflow (recursion) | SIGSEGV         | Low — denial of service          |
| Assertion failure          | SIGABRT         | Low — logic bug indicator        |

### Crash Triage Script

```bash
#!/usr/bin/env bash
# Triage crashes: reproduce, classify, and extract context
set -euo pipefail

CRASH_DIR="$1"
HARNESS="./harness"
OUTPUT_DIR="$2"

mkdir -p "$OUTPUT_DIR"

for crash in "$CRASH_DIR"/id:*; do
    crash_name=$(basename "$crash")
    echo "=== Triaging $crash_name ==="

    # Run under GDB in batch mode to capture backtrace
    gdb -batch \
        -ex "run" \
        -ex "bt" \
        -ex "info registers" \
        -ex "quit" \
        --args "$HARNESS" "$crash" \
        > "$OUTPUT_DIR/${crash_name}.gdb.txt" 2>&1

    # Check if it's a new unique crash (compare backtraces)
    bt_hash=$(grep "^#" "$OUTPUT_DIR/${crash_name}.gdb.txt" | md5sum | cut -d' ' -f1)
    echo "$bt_hash $crash_name" >> "$OUTPUT_DIR/crash_hashes.txt"

    # Extract crash type
    if grep -q "heap-buffer-overflow" "$OUTPUT_DIR/${crash_name}.gdb.txt"; then
        echo "HEAP_OVERFLOW $crash_name" >> "$OUTPUT_DIR/classified.txt"
    elif grep -q "stack-buffer-overflow" "$OUTPUT_DIR/${crash_name}.gdb.txt"; then
        echo "STACK_OVERFLOW $crash_name" >> "$OUTPUT_DIR/classified.txt"
    elif grep -q "use-after-free" "$OUTPUT_DIR/${crash_name}.gdb.txt"; then
        echo "UAF $crash_name" >> "$OUTPUT_DIR/classified.txt"
    elif grep -q "SEGV" "$OUTPUT_DIR/${crash_name}.gdb.txt"; then
        echo "NULL_DEREF $crash_name" >> "$OUTPUT_DIR/classified.txt"
    else
        echo "UNKNOWN $crash_name" >> "$OUTPUT_DIR/classified.txt"
    fi
done

echo "=== Crash Summary ==="
sort "$OUTPUT_DIR/classified.txt" | uniq -c | sort -rn
```

## AddressSanitizer Integration

ASan catches memory bugs that AFL++ might miss (heap overflows, UAF, double-free):

```bash
# Compile target with ASan
CC=afl-clang-fast CXX=afl-clang-fast++ \
  CFLAGS="-fsanitize=address -fno-omit-frame-pointer -g" \
  LDFLAGS="-fsanitize=address" \
  make

# Run fuzzer with ASan — crashes produce detailed reports
afl-fuzz -i corpus/ -o findings/ -- ./harness_asan @@
```

## Persistent Session Memory

Record fuzzing results in the session memory system (see SESSION-MEMORY.md).
Use knowledge type `crash_pattern` for confirmed crashes and `tool_config` for
effective corpus/fuzzing configurations. Record each crash as a separate entry
with crash type, target function, and input characteristics.

## Workflow Integration

In the phased workflow (see WORKFLOW.md):

1. **Phase 3 (Static Triage)** — Identify native libraries, extract strings, detect input formats
2. **Phase 3.7 (Semgrep)** — Scan Java/Kotlin code for JNI call patterns
3. **Phase 3.9 (CodeQL)** — Trace dataflow from Java to JNI boundaries
4. **Phase 5.5 (Native Fuzzing)** — Fuzz identified native entry points
5. **Phase 6 (Crash Analysis)** — Triage, classify, and validate crashes
6. **Phase 9 (PoC Development)** — Build exploit PoCs for confirmed crashes

Save all fuzzing artifacts to:

- `~/Documents/<app>/analysis/native-libs/` — extracted libraries
- `~/Documents/<app>/analysis/fuzz-corpus/` — seeds and corpus
- `~/Documents/<app>/analysis/fuzz-findings/` — crashes and triage
- `~/Documents/<app>/scripts/` — harnesses and analysis scripts

## Practical Tips

- Start with QEMU mode (binary-only) — it requires no source and catches most bugs
- Always generate format-aware seeds before running — random mutation finds less
- 30 minutes of fuzzing at 1000+ exec/sec is usually enough for initial triage
- If no crashes after 1 hour, try different target functions or input formats
- Use ASan builds for deeper bug detection once initial crashes are found
- Save the corpus — it can be reused and extended in future sessions
- Focus on heap/stack overflows and UAF — these have the highest exploitability
- Record execution speed — if below 100/sec, the harness or target is too slow
