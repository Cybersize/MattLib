"""Create a reproducible source + distribution archive beside the repository."""
from __future__ import annotations
import hashlib
import json
import zipfile
from pathlib import Path
from xml.etree import ElementTree
import build
import build_preview

def main():
    root=build.ROOT
    bundle,manifest=build.bundle()
    if (root/'Preview.lua').read_text(encoding='utf-8')!=build_preview.preview()[0]:
        raise SystemExit('Stale preview: run scripts/build_preview.py')
    if (root/"dist/Library.lua").read_text(encoding="utf-8")!=bundle:
        raise SystemExit("Stale distribution: run scripts/build.py")
    place=ElementTree.parse(root/"dist/MattLib-Showcase.rbxlx")
    place_bundle=None
    for item in place.findall(".//Item[@class='ModuleScript']"):
        if item.find("./Properties/string[@name='Name']").text=="MattLib":
            place_bundle=item.find("./Properties/ProtectedString[@name='Source']").text
    if place_bundle!=bundle:
        raise SystemExit("Stale showcase: run scripts/studio_place.py")
    destination=root.parent/"MattLib.zip"
    excluded={".git",".build",".tools","__pycache__",".pytest_cache"}
    files=[file for file in sorted(root.rglob("*")) if file.is_file() and not excluded.intersection(file.relative_to(root).parts) and file.suffix not in {".pyc",".tmp"}]
    with zipfile.ZipFile(destination,"w",compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for file in files:
            entry=zipfile.ZipInfo("MattLib/"+file.relative_to(root).as_posix(),date_time=(1980,1,1,0,0,0))
            entry.compress_type=zipfile.ZIP_DEFLATED
            entry.external_attr=0o644<<16
            archive.writestr(entry,file.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    result={"archive":destination.name,"files":len(files),"bytes":destination.stat().st_size,
            "sha256":hashlib.sha256(destination.read_bytes()).hexdigest(),"bundle_sha256":manifest["bundle_sha256"]}
    (root.parent/"MattLib-package.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(result,indent=2))

if __name__=="__main__": main()
