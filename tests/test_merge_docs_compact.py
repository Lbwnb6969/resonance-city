"""防止合并阅读稿丢失技术内容。"""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("merge_docs", Path(__file__).parents[1] / "tools/merge_docs_compact.py")
merge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(merge)


class CompactDocsTests(unittest.TestCase):
    def compact(self, raw):
        return merge.compact_source(raw, merge.DOCS / "01_执行规格/spec.audio.md")

    def test_formula_identifiers_and_code_are_preserved(self):
        raw = "**规则** `source_event_id`\n```python\nvalue = a * b * c\nprint('**保留**')\n\n```\n`a**2` 与 ``a`b``"
        output = self.compact(raw)
        self.assertIn("规则 `source_event_id`", output)
        self.assertIn(raw[raw.index("```python"):], output)

    def test_table_empty_cells_and_pipes_are_preserved(self):
        raw = "| 字段 | 说明 |\n|---|---|\n| `a|b` | |\n| c | 转义\\|值 |"
        self.assertEqual(self.compact(raw), raw)

    def test_substantive_history_line_and_link_targets_survive(self):
        raw = "第173轮规则：≤0.5s。验证见 `验证记录/round173/`。\n[协议](../02_验收/DOD.md) [源码](https://example.org/a?q=1#b)"
        output = self.compact(raw)
        self.assertIn(raw.splitlines()[0], output)
        self.assertIn("[协议](02_验收/DOD.md)", output)
        self.assertIn("[源码](https://example.org/a?q=1#b)", output)

    def test_fences_and_multiline_code_do_not_strip_content(self):
        raw = "~~~text\n---\n# title\n**bold**\n~~~\n`span\n**kept**`"
        self.assertEqual(self.compact(raw), raw)

    def test_heading_and_anchor_link_point_to_original_source(self):
        self.assertEqual(self.compact("# 标题\n[规则](#表-a1)"),
                         "### 标题\n[规则](01_执行规格/spec.audio.md#表-a1)")

    def test_markdown_examples_inside_inline_code_are_not_relocated(self):
        raw = "示例 `[链接](relative.md)` 和 ``[a](#b)``"
        self.assertEqual(self.compact(raw), raw)


if __name__ == "__main__":
    unittest.main()
