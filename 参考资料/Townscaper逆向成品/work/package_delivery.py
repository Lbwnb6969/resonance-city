"""Relocate the versioned Townscaper deliverable and preserve database archives."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import zipfile
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
DEST=Path(r'C:\Users\Administrator\Desktop\mIDDLEFILE\Townscaper逆向成品')

def sha(path):
    h=hashlib.sha256()
    with path.open('rb') as f:
        for data in iter(lambda:f.read(1024*1024),b''):h.update(data)
    return h.hexdigest()

def archive_database(source,name):
    folder=DEST/'备份'
    folder.mkdir(parents=True,exist_ok=True)
    final=folder/name
    if final.exists():
        with zipfile.ZipFile(final) as z:
            manifest=json.loads(z.read('ARCHIVE_MANIFEST.json').decode('utf-8'))
            records=manifest['files']
            for record in records:
                h=hashlib.sha256()
                with z.open(record['file']) as f:
                    for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
                assert h.hexdigest()==record['sha256'] and sha(source/record['file'])==record['sha256']
        return {'source':str(source),'archive':str(final),'files':len(records),'original_bytes':sum(x['bytes'] for x in records),'archive_bytes':final.stat().st_size,'sha256':sha(final),'verified':True}
    temporary=final.with_suffix('.partial.zip')
    records=[]
    with zipfile.ZipFile(temporary,'w',zipfile.ZIP_DEFLATED,compresslevel=6,allowZip64=True) as z:
        for file in sorted(source.rglob('*')):
            if file.is_file():
                relative=file.relative_to(source).as_posix()
                records.append({'file':relative,'bytes':file.stat().st_size,'sha256':sha(file)})
                z.write(file,relative)
        z.writestr('ARCHIVE_MANIFEST.json',json.dumps({'original_path':str(source),'files':records},ensure_ascii=False,indent=2))
    with zipfile.ZipFile(temporary) as z:
        for record in records:
            h=hashlib.sha256()
            with z.open(record['file']) as f:
                for block in iter(lambda:f.read(1024*1024),b''):h.update(block)
            assert h.hexdigest()==record['sha256'],record['file']
    temporary.rename(final)
    return {'source':str(source),'archive':str(final),'files':len(records),'original_bytes':sum(x['bytes'] for x in records),'archive_bytes':final.stat().st_size,'sha256':sha(final),'verified':True}

def package():
    DEST.mkdir(parents=True,exist_ok=True)
    tracked=subprocess.check_output(['git','ls-files','-z'],cwd=ROOT).decode('utf-8').split('\0')
    records=[]
    for name in tracked:
        if not name:continue
        source=ROOT/name
        if not source.is_file():continue
        target=DEST/name
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source,target)
        relocated=False
        if target.suffix.lower()=='.md':
            text=target.read_text(encoding='utf-8')
            def link(match):
                nonlocal relocated
                url=match.group(1).strip('<>')
                suffix=''
                loc=re.match(r'^(.*?)(:\d+)$',url)
                if loc:url,suffix=loc.groups()
                canonical=url.replace('\\','/')
                prefix=str(ROOT).replace('\\','/')+'/'
                if canonical.lower().startswith(prefix.lower()):
                    dest_link=DEST/canonical[len(prefix):]
                    url=os.path.relpath(dest_link,target.parent).replace('\\','/')+suffix
                    relocated=True
                return ']('+url+')'
            text=re.sub(r'\]\(([^)]+)\)',link,text)
            target.write_text(text,encoding='utf-8',newline='\n')
        records.append({'file':name,'source_sha256':sha(source),'delivered_sha256':sha(target),'bytes':target.stat().st_size,'links_relocated':relocated})
    bundle=DEST/'备份'/'Townscaper-Git.bundle'
    bundle.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['git','bundle','create',str(bundle),'--all'],cwd=ROOT,check=True,capture_output=True)
    subprocess.run(['git','bundle','verify',str(bundle)],cwd=ROOT,check=True,capture_output=True)
    for record in records:assert sha(DEST/record['file'])==record['delivered_sha256']
    invalid=[];links=0
    for name in tracked:
        file=DEST/name
        if not file.is_file() or file.suffix!='.md':continue
        for url in re.findall(r'\]\(([^)]+)\)',file.read_text(encoding='utf-8')):
            if url.startswith(('http:','https:','#')):continue
            url=re.sub(r':\d+$','',url.strip('<>'))
            path=Path(url) if re.match(r'^[a-zA-Z]:[/\\]',url) else file.parent/url
            if not path.exists():invalid.append({'document':name,'target':url})
            links+=1
    assert not invalid,invalid
    report={'source_workspace':str(ROOT),'destination':str(DEST),'git_commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'files':records,'file_count':len(records),'total_file_bytes':sum(x['bytes'] for x in records),'markdown_links_checked':links,'missing_links':invalid,'git_bundle':{'file':'备份/Townscaper-Git.bundle','sha256':sha(bundle),'bytes':bundle.stat().st_size,'verified':True},'limits':'Markdown links to source workspace were relocated. Evidence JSON retains original provenance paths and hashes; native/asset/program payload bytes were copied exactly. Rebuildable external tools and dependencies are omitted. Database/private snapshots are preserved separately in backup archives.'}
    (DEST/'交付清单.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
    (DEST/'README.md').write_text('''# Townscaper 逆向成品

先打开 [完整调查索引](outputs/townscaper_complete_index.md)。

- `outputs`：报告、2175原生函数、资源、84份重建HLSL、编解码器与验证结果。
- `work`：可复核脚本和IL2CPP恢复元数据；外部工具/可重建依赖未打包。
- `备份`：完整Git bundle及校验后的Ghidra数据库压缩备份。
- `discarded`：少量有复核价值的早期失败输出，保留不删。
- `交付清单.json`：每个文件来源/交付SHA-256和链接迁移检查。
- `清理记录.json`：清理位置、归档校验和释放空间。

普通使用只读报告，存档工具无外部Python依赖：

```powershell
python outputs/townscaper_codec.py self-test
python outputs/townscaper_codec.py decode town.txt -o town.json
python outputs/townscaper_codec.py encode town.json -o rebuilt.txt
```

恢复Git历史：`git clone 备份/Townscaper-Git.bundle 恢复项目`。
恢复Ghidra：解压“Ghidra完成项目.zip”到项目目录并打开Townscaper.gpr。压缩包包含逐文件SHA-256清单。原安装工具继续保留在原工作区；以后启动REA/Ghidra需解压数据库到原路径或指定新的项目目录。

这是发行版本业务层逆向交付，不是作者原工程或独立可运行游戏。JSON里的原安装/工作区路径属于证据来源，保留未改；Markdown内部引用已迁移，可从这里查阅。私有存档/注册表/许可证不在公开Git bundle中。
''',encoding='utf-8',newline='\n')
    print(json.dumps({k:report[k] for k in ('destination','file_count','total_file_bytes','markdown_links_checked')},ensure_ascii=False))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('mode',choices=['package','archive']);args=parser.parse_args()
    if args.mode=='package':package()
    else:
        DEST.mkdir(parents=True,exist_ok=True)
        records=[archive_database(ROOT/'work/ghidra_project21','Ghidra完成项目.zip')]
        # Preserve private setup/user snapshots separately from the shareable Git history.
        private=DEST/'备份'/'私有配置与存档快照'
        for source in [ROOT/'work/runtime',ROOT/'work/tools/config-backups',ROOT/'work/tools/license-backups',ROOT/'work/废弃']:
            if not source.exists():continue
            target=private/source.name
            shutil.copytree(source,target,ignore=shutil.ignore_patterns('ghidra_incomplete_20261013'),dirs_exist_ok=True)
        (DEST/'数据库归档校验.json').write_text(json.dumps(records,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
        print(json.dumps(records,ensure_ascii=False))
