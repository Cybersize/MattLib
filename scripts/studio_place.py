"""Generate an offline Studio place from the same distribution and working examples."""
from pathlib import Path
from xml.etree.ElementTree import Element, SubElement, ElementTree
import build

ROOT=build.ROOT
counter=0
def item(parent,cls,name,source=None):
    global counter
    counter+=1
    result=SubElement(parent,"Item",{"class":cls,"referent":f"RBX{counter}"})
    properties=SubElement(result,"Properties")
    SubElement(properties,"string",{"name":"Name"}).text=name
    if source is not None:
        SubElement(properties,"ProtectedString",{"name":"Source"}).text=source
    return result

def main():
    bundle,_=build.bundle()
    root=Element("roblox",{"version":"4"})
    SubElement(root,"External").text="null"
    SubElement(root,"External").text="nil"
    item(root,"Workspace","Workspace")
    storage=item(root,"ReplicatedStorage","ReplicatedStorage")
    item(storage,"ModuleScript","MattLib",bundle)
    item(storage,"ModuleScript","AsterSmoke",(ROOT/"tests/studio/Smoke.luau").read_text(encoding="utf-8"))
    examples=item(storage,"Folder","AsterExamples")
    for name,folder in {"Gallery":"component-gallery","Dashboard":"complex-dashboard","Basic":"basic","Declarative":"declarative"}.items():
        item(examples,"ModuleScript",name,(ROOT/f"examples/{folder}/init.luau").read_text(encoding="utf-8"))
    player=item(root,"StarterPlayer","StarterPlayer")
    scripts=item(player,"StarterPlayerScripts","StarterPlayerScripts")
    item(scripts,"LocalScript","AsterBootstrap",(ROOT/"tests/studio/Bootstrap.client.luau").read_text(encoding="utf-8"))
    destination=ROOT/"dist/MattLib-Showcase.rbxlx"
    destination.parent.mkdir(exist_ok=True)
    ElementTree(root).write(destination,encoding="utf-8",xml_declaration=True)
    print(f"Generated {destination}")

if __name__=="__main__": main()
