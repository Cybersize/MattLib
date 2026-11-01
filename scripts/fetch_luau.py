"""Optional developer bootstrap: official Luau 0.744, verified by pinned SHA-256."""
from __future__ import annotations
import argparse
import hashlib
import io
import os
import platform
import urllib.request
import zipfile
from pathlib import Path

VERSION="0.744"
ASSETS={
    "Windows":("luau-windows.zip","fde3e22c557aac6afe20a34e8050b7d8c290fa42638c04274a307ed5d0ef0db8"),
    "Linux":("luau-ubuntu.zip","6506f0852c623aaffcb28494aac16c26dc04a269ea0e16cc0aafc8c8ac79f3ec"),
    "Darwin":("luau-macos.zip","ae34a55253bd7eb291723ffdf0143d59128a42b6e62f774ee6f6fbfbef8e5a06"),
}

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument("--destination",type=Path,default=Path(__file__).resolve().parents[1]/".tools"/VERSION)
    args=parser.parse_args()
    asset,digest=ASSETS[platform.system()]
    url=f"https://github.com/luau-lang/luau/releases/download/{VERSION}/{asset}"
    with urllib.request.urlopen(url,timeout=60) as response:
        data=response.read()
    if hashlib.sha256(data).hexdigest()!=digest:
        raise SystemExit("Luau archive checksum mismatch; refusing to extract")
    destination=args.destination.resolve()
    destination.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for member in archive.infolist():
            target=(destination/member.filename).resolve()
            if not target.is_relative_to(destination):
                raise SystemExit("Unsafe archive path")
        archive.extractall(destination)
    if os.name!="nt":
        for file in destination.iterdir():
            if file.is_file() and file.name.startswith("luau"):
                file.chmod(file.stat().st_mode|0o111)
    print(f"Verified official Luau {VERSION} at {destination}")

if __name__=="__main__": main()
