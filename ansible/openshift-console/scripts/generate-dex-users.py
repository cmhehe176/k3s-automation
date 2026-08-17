#!/usr/bin/env python3
import sys
import json
import uuid
import subprocess

def get_bcrypt_hash(username, password):
    # 1. Try python standard crypt blowfish
    try:
        import crypt
        h = crypt.crypt(password, crypt.mksalt(crypt.METHOD_BLOWFISH))
        if h:
            if h.startswith('$2b$') or h.startswith('$2y$'):
                h = '$2a$' + h[4:]
            return h
    except Exception:
        pass

    # 2. Try htpasswd
    try:
        res = subprocess.run(['htpasswd', '-BinC', '10', username, password], capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            h = res.stdout.strip().split(':')[-1]
            if h.startswith('$2y$') or h.startswith('$2b$'):
                h = '$2a$' + h[4:]
            return h
    except Exception:
        pass

    return None

def main():
    if len(sys.argv) < 2:
        return

    users_input = json.loads(sys.argv[1])
    out_file = sys.argv[2] if len(sys.argv) > 2 else "/tmp/openshift-console/users_hashed.json"

    output = []
    for u in users_input:
        username = u.get("username", "user")
        password = u.get("password", "")
        h = get_bcrypt_hash(username, password)
        output.append({
            "username": username,
            "email": u.get("email", f"{username}@local"),
            "password": password,
            "groups": u.get("groups", []),
            "hash": h,
            "userID": str(uuid.uuid4())
        })

    with open(out_file, "w") as f:
        json.dump(output, f)

if __name__ == "__main__":
    main()
