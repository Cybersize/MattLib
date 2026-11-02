from __future__ import annotations
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from xml.etree import ElementTree
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build
import build_preview

class BundleTests(unittest.TestCase):
    def setUp(self):
        base = os.environ.get("MATTLIB_TEST_WORKDIR")
        if base:
            Path(base).mkdir(parents=True, exist_ok=True)
        self.directory = tempfile.TemporaryDirectory(dir=base)
        self.source = Path(self.directory.name)
        self.override = patch.object(build, "SOURCE", self.source)
        self.override.start()

    def tearDown(self):
        self.override.stop()
        self.directory.cleanup()

    def write(self, name, contents):
        file = self.source / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_text(contents, encoding="utf-8")

    def test_dependency_resolution_and_cache_are_self_contained(self):
        self.write("init.luau", "local Value=require(script.core.Value)\nreturn Value")
        self.write("core/Value.luau", "return require(script.Parent.Shared)")
        self.write("core/Shared.luau", "return {answer=42}")
        output, manifest = build.bundle()
        self.assertEqual(manifest["modules"], 3)
        self.assertIn('__require("core/Shared")', output)
        self.assertIn("__cache[id] = value", output)
        self.assertNotIn("require(script", output)
        self.assertNotIn("loadstring", output)

    def test_deterministic_output(self):
        self.write("init.luau", "return {}")
        self.assertEqual(build.bundle(), build.bundle())

    def test_unknown_import_is_rejected(self):
        self.write("init.luau", "return require(script.missing)")
        with self.assertRaisesRegex(ValueError, "Unresolved import"):
            build.bundle()

    def test_dynamic_import_is_rejected(self):
        self.write("init.luau", "return require(anything)")
        with self.assertRaisesRegex(ValueError, "Dynamic/unsupported"):
            build.bundle()

    def test_cyclic_import_is_rejected(self):
        self.write("init.luau", "return require(script.a)")
        self.write("a.luau", "return require(script.Parent)")
        with self.assertRaisesRegex(ValueError, "Cyclic import"):
            build.bundle()

    def test_import_cannot_escape_source(self):
        self.write("init.luau", "return require(script.Parent.outside)")
        with self.assertRaisesRegex(ValueError, "escapes src"):
            build.bundle()

class DistributionTests(unittest.TestCase):
    def test_named_library_is_identical_to_standard_distribution(self):
        self.assertEqual((build.ROOT/'dist/MattLib.lua').read_text(encoding='utf-8'),build.bundle()[0])

    def test_preview_is_current_and_self_contained(self):
        source,_=build_preview.preview()
        self.assertEqual((build.ROOT/'Preview.lua').read_text(encoding='utf-8'),source)
        self.assertNotIn('game:HttpGet',source)
        self.assertNotIn('require(script',source)

    def test_checked_in_distribution_matches_source(self):
        text, _ = build.bundle()
        self.assertEqual((build.ROOT / "dist/Library.lua").read_text(encoding="utf-8"), text)

    def test_showcase_contains_identical_bundle_and_five_examples(self):
        tree = ElementTree.parse(build.ROOT / "dist/MattLib-Showcase.rbxlx")
        modules = {}
        for item in tree.findall(".//Item[@class='ModuleScript']"):
            name = item.find("./Properties/string[@name='Name']").text
            source = item.find("./Properties/ProtectedString[@name='Source']").text
            modules[name] = source
        self.assertEqual(modules["MattLib"], build.bundle()[0])
        self.assertTrue({"Gallery", "Dashboard", "Basic", "Declarative", "Designs", "AsterSmoke"} <= set(modules))

if __name__ == "__main__":
    unittest.main()
