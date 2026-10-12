from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "文档"
OUTPUT = DOCS / "共鸣之城_文档合并精简版.md"

ORDER = [
    "00_设计意图.md",
    "01_执行规格/spec.asset.md",
    "01_执行规格/spec.audio.md",
    "01_执行规格/spec.city.md",
    "01_执行规格/spec.fabric.md",
    "01_执行规格/spec.harmony.md",
    "01_执行规格/spec.proposal.md",
    "01_执行规格/spec.run.md",
    "01_执行规格/spec.space.md",
    "01_执行规格/spec.terrain.md",
    "01_执行规格/spec.ui.md",
    "10_世界模型.md",
    "11_核心循环.md",
    "12_声音架构.md",
    "13_地形与自然.md",
    "14_城市生长.md",
    "15_时代与地标.md",
    "16_界面与反馈.md",
    "17_美术规格.md",
    "18_城市规模.md",
    "19_城市生成管线.md",
    "02_验收/DOD.md",
    "03_任务/P0.md",
    "03_任务/P1.md",
    "03_任务/P2.md",
    "Demo快速开始.md",
    "待裁定与依赖.md",
    "参考索引.md",
    "参考资料AI索引.md",
    "施工文档规则.md",
]


def clean(line: str) -> str:
    line = line.strip()
    if not line or re.fullmatch(r"[-_*]{3,}", line):
        return ""
    if re.fullmatch(r"\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)+\|?", line):
        return ""
    if line.startswith("|") and line.endswith("|"):
        line = "；".join(cell.strip() for cell in line.strip("|").split("|") if cell.strip())
    line = re.sub(r"!\[([^]]*)\]\([^)]*\)", r"\1", line)
    line = re.sub(r"\[([^]]+)\]\([^)]*\)", r"\1", line)
    line = line.replace("**", "").replace("__", "").replace("`", "")
    line = re.sub(r"(?<!\*)\*([^*]+)\*(?!\*)", r"\1", line)
    line = line.replace("“", "").replace("”", "").replace("‘", "").replace("’", "")
    line = re.sub(r"[ \t]+", " ", line)
    line = re.sub(r"([，。；：、])\1+", r"\1", line)
    return line.strip()


def drop_process_line(line: str) -> bool:
    return bool(
        re.match(r"^第\d+轮", line)
        or re.match(r"^\d{4}-\d{2}-\d{2}.*重构追加段", line)
        or re.match(r"^本轮(?:新增|补|已|把|将|继续|完成|通过)", line)
        or "验证记录/round" in line
        or "验证记录\\round" in line
        or re.match(r"^旧 P[012] 的", line)
    )


def build() -> None:
    output = [
        "# 共鸣之城：文档合并精简版",
        "",
        "本文件由文档目录中的现行 Markdown 合并生成。原文件保持不变。",
        "已删除重复导航、空白行、表格分隔线、历史轮次记录和 Markdown 装饰符号；公式、阈值、字段、路径、命令、许可与验收条件保留。",
        "阅读顺序：设计意图 → 执行规格 → 系统设计 → 验收与任务 → Demo 操作 → 待裁定与参考。",
        "",
        "## 使用规则",
        "执行规格是公式、阈值、字段、提交边界和验收口径的唯一权威；00 与 10–19 解释设计意图和系统关系；PROJECT.md 记录当前进度、验证结论和下一步；待裁定与依赖只列仍影响工作的缺口。",
        "普通建筑自动生长，玩家控制社区规划、公共锚点、声音选择和调音。外部参考按任务选择，不把历史报告、废弃文档或旧规格当作当前规则。新规则写入所属章节，过程记录写入 PROJECT.md、任务单或验证记录，不建立平行入口。",
        "",
    ]

    for relative in ORDER:
        path = DOCS / relative
        raw_lines = path.read_text(encoding="utf-8").splitlines()
        title = next(
            (clean(line)[2:].strip() for line in raw_lines if line.lstrip().startswith("# ")),
            path.stem,
        )
        output.extend([f"## {title}", f"来源：文档/{relative}", ""])
        skipped_title = False
        for raw_line in raw_lines:
            line = clean(raw_line)
            if not line or drop_process_line(line):
                continue
            if line.lstrip("# ").strip() == title and not skipped_title:
                skipped_title = True
                continue
            if line.startswith("# "):
                line = "## " + line[2:].strip()
            output.append(line)
        output.append("")

    compact = []
    for line in output:
        if line == "" and compact and compact[-1] == "":
            continue
        compact.append(line)
    OUTPUT.write_text("\n".join(compact).rstrip() + "\n", encoding="utf-8")
    print(f"merged {len(compact)} lines {OUTPUT.stat().st_size} bytes")


if __name__ == "__main__":
    build()
