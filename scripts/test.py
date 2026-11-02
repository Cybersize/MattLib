"""Compile source/examples and run the actual standalone bundle in the Luau CLI."""
from __future__ import annotations
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path
import build
import build_preview

ROOT = build.ROOT

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--luau", default=shutil.which("luau"))
    parser.add_argument("--compiler", default=shutil.which("luau-compile"))
    parser.add_argument("--work-dir", type=Path, default=ROOT / ".build")
    args = parser.parse_args()
    if not args.luau or not args.compiler:
        parser.error("Install the Luau CLI, or supply --luau and --compiler paths")
    bundle, manifest = build.bundle()
    build_dir = args.work_dir
    build_dir.mkdir(parents=True, exist_ok=True)
    mock = (ROOT / "tests/MockRoblox.luau").read_text(encoding="utf-8")
    cases = (ROOT / "tests/Framework.spec.luau").read_text(encoding="utf-8")
    examples = "local Examples={}\n"
    for folder in ("basic", "declarative", "component-gallery", "complex-dashboard", "design-selection"):
        source=(ROOT/f"examples/{folder}/init.luau").read_text(encoding="utf-8")
        examples+=f"Examples[{json.dumps(folder)}]=(function()\n{source}\nend)()\n"
    runner = build_dir / "tests.generated.luau"
    runner.write_text("local Mock=(function()\n" + mock + "\nend)()\n" +
        "local Instance,Vector2,Color3,UDim,UDim2,Enum,typeof,task,game,TweenInfo,workspace,warn,ColorSequence,NumberSequence = " +
        "Mock.Instance,Mock.Vector2,Mock.Color3,Mock.UDim,Mock.UDim2,Mock.Enum,Mock.typeof,Mock.task,Mock.game,Mock.TweenInfo,Mock.workspace,Mock.warn,Mock.ColorSequence,Mock.NumberSequence\n" +
        "local createBundle=function()\n" + bundle + "\nend\nlocal Library=createBundle()\n" + examples + cases, encoding="utf-8", newline="\n")
    preview_source,preview_manifest=build_preview.preview()
    preview_runner=build_dir/'preview.generated.luau'
    preview_runner.write_text('local Mock=(function()\n'+mock+'\nend)()\n'+
        'local Instance,Vector2,Color3,UDim,UDim2,Enum,typeof,task,game,TweenInfo,workspace,warn,ColorSequence,NumberSequence = '+
        'Mock.Instance,Mock.Vector2,Mock.Color3,Mock.UDim,Mock.UDim2,Mock.Enum,Mock.typeof,Mock.task,Mock.game,Mock.TweenInfo,Mock.workspace,Mock.warn,Mock.ColorSequence,Mock.NumberSequence\n'+
        'local app=(function()\n'+preview_source+'\nend)()\nMock.flush()\nassert(app.root.alive)\n'+
        'assert(app.library:GetDiagnostics().windows==1)\napp.Destroy()\nMock.advance(2)\n'+
        'for key,value in app.library:GetDiagnostics() do if key~="renders" then assert(value==0,"Preview leaked "..key) end end\n'+
        'assert(Mock.nativeConnections()==0)\nassert(#Mock.warnings==0,table.concat(Mock.warnings," | "))\nprint("PREVIEW passed: mounted gallery and released every managed resource")\n',encoding='utf-8',newline='\n')
    files = sorted(ROOT.glob("src/**/*.luau")) + sorted(ROOT.glob("examples/**/*.luau")) + sorted(ROOT.glob("examples/**/*.lua")) + sorted(ROOT.glob("tests/studio/**/*.luau")) + [ROOT / "dist/Library.lua", ROOT/'dist/MattLib.lua', ROOT/'Preview.lua', runner, preview_runner]
    failures = []
    for file in files:
        result = subprocess.run([args.compiler, "--null", str(file)], capture_output=True, text=True)
        if result.returncode:
            failures.append({"file": str(file), "output": result.stdout + result.stderr})
    if failures:
        for failure in failures:
            print(failure["file"], failure["output"])
        raise SystemExit(1)
    print(f"Compiled {len(files)} Luau files successfully")
    result = subprocess.run([args.luau, str(runner)], capture_output=True, text=True)
    print(result.stdout, end="")
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    preview_result=subprocess.run([args.luau,str(preview_runner)],capture_output=True,text=True)
    print(preview_result.stdout,end='')
    if preview_result.stderr:
        print(preview_result.stderr,file=sys.stderr)
    report = {"tool": "Luau CLI", "compiler_files": len(files), "bundle_sha256": manifest["bundle_sha256"],
              "exit_code": result.returncode, "output": result.stdout, "stderr": result.stderr,
              "scope": "Actual bundled runtime against tests/MockRoblox.luau; no engine visual claims"}
    (ROOT / "tests/results.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    (ROOT/'tests/preview-results.json').write_text(json.dumps({'tool':'Luau CLI','preview_sha256':preview_manifest['preview_sha256'],
        'exit_code':preview_result.returncode,'output':preview_result.stdout,'stderr':preview_result.stderr,
        'scope':'Actual self-contained Preview.lua and engine double; no native visual or executor claims'},indent=2)+'\n',encoding='utf-8')
    raise SystemExit(result.returncode or preview_result.returncode)

if __name__ == "__main__":
    main()
