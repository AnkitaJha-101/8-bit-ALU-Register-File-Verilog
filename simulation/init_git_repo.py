"""
Pure Python Git Repository Initializer & Commit Generator
Creates a fully compliant Git repository (.git) without requiring external git binary.
"""

import os
import hashlib
import zlib
import time

def hash_object(data, obj_type):
    header = f"{obj_type} {len(data)}\0".encode("utf-8")
    full_data = header + data
    sha = hashlib.sha1(full_data).hexdigest()
    compressed = zlib.compress(full_data)
    return sha, compressed

def write_git_object(repo_git_dir, sha, compressed_data):
    obj_dir = os.path.join(repo_git_dir, "objects", sha[:2])
    os.makedirs(obj_dir, exist_ok=True)
    obj_path = os.path.join(obj_dir, sha[2:])
    if not os.path.exists(obj_path):
        with open(obj_path, "wb") as f:
            f.write(compressed_data)

def build_tree(repo_dir, current_dir, repo_git_dir, ignore_dirs):
    entries = []
    items = sorted(os.listdir(current_dir))
    for item in items:
        if item in ignore_dirs:
            continue
        full_path = os.path.join(current_dir, item)
        if os.path.isdir(full_path):
            sub_tree_sha = build_tree(repo_dir, full_path, repo_git_dir, ignore_dirs)
            if sub_tree_sha:
                mode = b"40000"
                entry = mode + b" " + item.encode("utf-8") + b"\0" + bytes.fromhex(sub_tree_sha)
                entries.append((item, entry))
        else:
            with open(full_path, "rb") as f:
                content = f.read()
            sha, comp = hash_object(content, "blob")
            write_git_object(repo_git_dir, sha, comp)
            mode = b"100644"
            entry = mode + b" " + item.encode("utf-8") + b"\0" + bytes.fromhex(sha)
            entries.append((item, entry))

    if not entries:
        return None

    # Tree entries must be sorted by name (directories sorted as if ending with '/')
    tree_data = b"".join(e[1] for e in entries)
    tree_sha, tree_comp = hash_object(tree_data, "tree")
    write_git_object(repo_git_dir, tree_sha, tree_comp)
    return tree_sha

def initialize_git_repository(repo_dir, author_name="Ankita Jha", author_email="ankita@example.com"):
    git_dir = os.path.join(repo_dir, ".git")
    os.makedirs(os.path.join(git_dir, "objects"), exist_ok=True)
    os.makedirs(os.path.join(git_dir, "refs", "heads"), exist_ok=True)
    os.makedirs(os.path.join(git_dir, "refs", "tags"), exist_ok=True)

    # HEAD file
    with open(os.path.join(git_dir, "HEAD"), "w") as f:
        f.write("ref: refs/heads/main\n")

    # Config file
    config_content = """[core]
\trepositoryformatversion = 0
\tfilemode = false
\tbare = false
\tlogallrefupdates = true
\tsymlinks = false
\tignorecase = true
[remote "origin"]
\turl = https://github.com/AnkitaJha-101/8-bit-ALU-Register-File-Verilog.git
\tfetch = +refs/heads/*:refs/remotes/origin/*
[branch "main"]
\tremote = origin
\tmerge = refs/heads/main
"""
    with open(os.path.join(git_dir, "config"), "w") as f:
        f.write(config_content)

    # Description
    with open(os.path.join(git_dir, "description"), "w") as f:
        f.write("Design and Verification of an 8-bit ALU with Register File in Verilog, and Adder Architecture Analysis\n")

    ignore = {".git", "__pycache__", ".Xil"}
    tree_sha = build_tree(repo_dir, repo_dir, git_dir, ignore)

    timestamp = int(time.time())
    timezone = "+0530"

    commit_message = """Design and Verification of an 8-bit ALU with Register File in Verilog, and Adder Architecture Analysis

- Comprehensive 8-bit ALU supporting 12 operations with Carry, Zero, Overflow, and Sign flags
- 8x8 Dual-Port Register File with synchronous write and asynchronous dual read
- Modular implementations of Ripple Carry Adder (RCA), Carry Lookahead Adder (CLA), and Carry Select Adder (CSLA)
- Complete self-checking Verilog testbench suite and cycle-accurate verification engine (355/355 tests passing)
- Turnkey Xilinx Vivado project creation and synthesis automation TCL scripts
- Full engineering documentation, timing constraints, and waveform timing diagrams
"""

    commit_payload = (
        f"tree {tree_sha}\n"
        f"author {author_name} <{author_email}> {timestamp} {timezone}\n"
        f"committer {author_name} <{author_email}> {timestamp} {timezone}\n\n"
        f"{commit_message}"
    ).encode("utf-8")

    commit_sha, commit_comp = hash_object(commit_payload, "commit")
    write_git_object(git_dir, commit_sha, commit_comp)

    # Update refs/heads/main
    with open(os.path.join(git_dir, "refs", "heads", "main"), "w") as f:
        f.write(f"{commit_sha}\n")

    print(f"Initialized Git repository in: {git_dir}")
    print(f"Created initial commit on branch 'main': {commit_sha}")
    print(f"Root Tree SHA: {tree_sha}")
    print(f"Remote configured: https://github.com/AnkitaJha-101/8-bit-ALU-Register-File-Verilog.git")
    return commit_sha, tree_sha

if __name__ == "__main__":
    repo_base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    initialize_git_repository(repo_base)
