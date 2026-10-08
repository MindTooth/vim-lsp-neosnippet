"""One completion item for the omnifunc regression test."""
import json
import sys

snippet = json.load(open(sys.argv[1]))
while True:
    headers = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            sys.exit(0)
        if line == b"\r\n":
            break
        key, value = line.decode().split(":", 1)
        headers[key.lower()] = value.strip()
    message = json.loads(sys.stdin.buffer.read(int(headers["content-length"])))
    if "id" not in message:
        if message.get("method") == "exit":
            break
        continue
    method = message.get("method")
    result = None
    if method == "initialize":
        result = {"capabilities": {"textDocumentSync": 1, "completionProvider": {}}}
    elif method == "textDocument/completion":
        result = [{"label": "example", "insertTextFormat": 2, "insertText": snippet}]
    body = json.dumps({"jsonrpc": "2.0", "id": message["id"], "result": result}).encode()
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)
    sys.stdout.buffer.flush()
