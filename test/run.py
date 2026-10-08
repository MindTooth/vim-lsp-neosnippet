"""Run with dependency runtime paths in the environment; see README.md."""
import json
import os
from pathlib import Path
import pty
import select
import time
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parent.parent
cases = [
    ("multiline", 'object {\n\t"key": ${1:42}\n\\}$0', "  ", ['  object {', '    "key": 42', '  }']),
    ("literal dollar", r"\$1", "", ["$1"]),
    ("literal placeholder", r"\${1:cash}", "", ["${1:cash}"]),
    ("escaped brace", r"a\}b", "", ["a}b"]),
    ("brace in default", r"${1:a\}b}$0", "", ["a}b"]),
    ("quotes", "quote's ${1:ok}$0", "", ["quote's ok"]),
    ("backslash before tabstop", r"\\$1", "", ["\\"]),
    ("backslash before brace", r"\\}", "", ["\\}"]),
    ("literal backticks", "`1 + 1` $0", "", ["`1 + 1` "]),
    ("tabstop order", "${2:second} ${1:first}$0", "", ["second first"]),
    ("unicode", "é${1:value}$0", "", ["évalue"]),
    ("plain text", "text", "", ["text"]),
]
cases += [("JSON object", '{\n\t"key": ${1:42}\n\\}$0', "  ", ['  {', '    "key": 42', '  }'])]
for name, snippet, prefix, expected in cases:
    for method in (["direct", "omni"] if name in ("multiline", "quotes", "unicode") else ["direct"]):
        with tempfile.TemporaryDirectory(prefix="lsp-neosnippet-", dir="/tmp") as tmp:
            tmp = Path(tmp)
            (tmp / "snippet.json").write_text(json.dumps(snippet))
            env = dict(os.environ, ADAPTER_RTP=os.environ.get("ADAPTER_RTP", str(root)),
                       PYTHON=sys.executable, SNIPPET_FILE=str(tmp / "snippet.json"),
                       BUFFER_FILE=str(tmp / "buffer.fixture"), PREFIX=prefix,
                       RESULT_FILE=str(tmp / "result.json"), COMPLETION_METHOD=method)
            master, slave = pty.openpty()
            process = subprocess.Popen([os.environ.get("VIM", "vim"), "-Nu", "NONE", "-n",
                                        "-i", "NONE", "-S", str(root / "test/completion.vim")],
                                       stdin=slave, stdout=slave, stderr=slave, env=env)
            os.close(slave)
            try:
                deadline = time.monotonic() + 8
                while process.poll() is None and time.monotonic() < deadline:
                    if select.select([master], [], [], 0.1)[0]:
                        try:
                            os.read(master, 65536)
                        except OSError:
                            break
                process.wait(timeout=max(0.1, deadline - time.monotonic()))
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
                raise AssertionError(f"{name}: Vim did not finish")
            finally:
                os.close(master)
            assert (tmp / "result.json").exists(), f"{name}: no result (exit {process.returncode})"
            result = json.loads((tmp / "result.json").read_text())
            assert result.get("lines") == expected, f"{name}: {result} != {expected}"
            assert result.get("error", "") in ("", "E490: No fold found"), result
            if name == "tabstop order":
                assert result["initial"]["lines"] == ["<`2:second`> first<`0`>"], result
                assert result["initial"]["cursor"] == [1, 18], result
            print(f"PASS: {name} ({method})")
