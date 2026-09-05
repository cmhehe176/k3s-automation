#!/usr/bin/env python3
import socket
import threading
import sys
import select
from urllib.parse import urlparse

PORT = 8888

def forward(src, dst):
    try:
        while True:
            r, _, _ = select.select([src], [], [], 60)
            if not r:
                break
            data = src.recv(65536)
            if not data:
                break
            dst.sendall(data)
    except Exception:
        pass
    finally:
        try: src.close()
        except: pass
        try: dst.close()
        except: pass

def handle_client(client_sock):
    try:
        client_sock.settimeout(15)
        raw_req = b""
        while b"\r\n\r\n" not in raw_req:
            chunk = client_sock.recv(4096)
            if not chunk:
                break
            raw_req += chunk
            if len(raw_req) > 65536:
                break

        if not raw_req:
            client_sock.close()
            return

        header_part, _, body_part = raw_req.partition(b"\r\n\r\n")
        lines = header_part.split(b"\r\n")
        first_line = lines[0].decode('latin1', errors='ignore')
        parts = first_line.split(" ")
        if len(parts) < 2:
            client_sock.close()
            return

        method, url = parts[0].upper(), parts[1]

        if method == "CONNECT":
            if ":" in url:
                host, port_str = url.split(":", 1)
                port = int(port_str)
            else:
                host, port = url, 443
            remote_sock = socket.create_connection((host, port), timeout=15)
            client_sock.sendall(b"HTTP/1.1 200 Connection Established\r\n\r\n")
            client_sock.settimeout(None)
            remote_sock.settimeout(None)
            t1 = threading.Thread(target=forward, args=(client_sock, remote_sock), daemon=True)
            t2 = threading.Thread(target=forward, args=(remote_sock, client_sock), daemon=True)
            t1.start()
            t2.start()
            t1.join()
            t2.join()
        else:
            parsed = urlparse(url)
            host = parsed.hostname or url.split("/")[0]
            port = parsed.port or (443 if parsed.scheme == "https" else 80)
            remote_sock = socket.create_connection((host, port), timeout=15)
            
            path = parsed.path or "/"
            if parsed.query:
                path += "?" + parsed.query
            new_first_line = f"{method} {path} {parts[2] if len(parts) > 2 else 'HTTP/1.1'}".encode('latin1')
            new_req = new_first_line + b"\r\n" + b"\r\n".join(lines[1:]) + b"\r\n\r\n" + body_part
            remote_sock.sendall(new_req)

            client_sock.settimeout(None)
            remote_sock.settimeout(None)
            t1 = threading.Thread(target=forward, args=(client_sock, remote_sock), daemon=True)
            t2 = threading.Thread(target=forward, args=(remote_sock, client_sock), daemon=True)
            t1.start()
            t2.start()
            t1.join()
            t2.join()
    except Exception:
        try: client_sock.close()
        except: pass

def main():
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(("0.0.0.0", PORT))
    server.listen(256)
    print(f"HTTP/HTTPS Proxy listening on 0.0.0.0:{PORT}", flush=True)
    while True:
        client_sock, _ = server.accept()
        t = threading.Thread(target=handle_client, args=(client_sock,), daemon=True)
        t.start()

if __name__ == "__main__":
    main()
