"""Run a fresh REA stdio process with the installed Ghidra environment."""
import json, os, subprocess, sys, pathlib, winreg

ROOT = pathlib.Path(__file__).resolve().parent.parent
NODE = r'C:\Users\Administrator\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
REA = r'C:\Users\Administrator\AppData\Local\npm-cache\_npx\af752b90495482d7\node_modules\rea-agents\scripts\rea.mjs'
env = os.environ.copy()
with winreg.OpenKey(winreg.HKEY_CURRENT_USER, 'Environment') as key:
    for name in ('JAVA_HOME', 'GHIDRA_INSTALL_DIR', 'REA_IDA_MCP_CONFIG'):
        try:
            env[name] = winreg.QueryValueEx(key, name)[0]
        except FileNotFoundError:
            pass
env['PATH'] = str(pathlib.Path(env['JAVA_HOME']) / 'bin') + os.pathsep + env['PATH']
env['REA_GHIDRA_STARTUP_TIMEOUT_MS'] = '3600000'
output_path = ROOT / 'outputs/townscaper_rea_evidence_v2.json'
if '--output' in sys.argv:
    output_path = pathlib.Path(sys.argv[sys.argv.index('--output') + 1]).resolve()
if '--schemas' not in sys.argv and output_path.exists():
    raise FileExistsError('Choose an absent --output path to preserve the previous Evidence bundle')
counter = 0
log = open(ROOT / 'work/rea_native_stderr.log', 'a', encoding='utf-8')
proc = subprocess.Popen([NODE, REA, 'mcp'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                        stderr=log, env=env, text=True, encoding='utf-8')

def request(method, params):
    global counter
    counter += 1
    proc.stdin.write(json.dumps({'jsonrpc':'2.0','id':counter,'method':method,'params':params})+'\n')
    proc.stdin.flush()
    for line in proc.stdout:
        reply = json.loads(line)
        if reply.get('id') == counter:
            if 'error' in reply:
                raise RuntimeError(reply['error'])
            return reply['result']
    raise RuntimeError('REA exited without reply')

def call(name, arguments):
    print(f'CALL {name}', flush=True)
    raw = request('tools/call', {'name':name, 'arguments':arguments})
    parsed = raw.get('structuredContent')
    if parsed is None:
        parsed = json.loads(next(c['text'] for c in raw['content'] if c['type']=='text'))
    return parsed

try:
    request('initialize', {'protocolVersion':'2024-11-05','capabilities':{},'clientInfo':{'name':'townscaper-analysis','version':'1.0'}})
    proc.stdin.write(json.dumps({'jsonrpc':'2.0','method':'notifications/initialized'})+'\n')
    proc.stdin.flush()
    catalog = request('tools/list', {})
    (ROOT / 'work/rea_tool_schemas.json').write_text(json.dumps(catalog, ensure_ascii=False, indent=2), encoding='utf-8')
    wanted = ('open_binary','analyze_function','export_evidence_bundle','get_evidence_bundle','close_binary','inspect_analysis_view')
    if '--schemas' in sys.argv:
        for tool in catalog['tools']:
            if tool['name'] in wanted:
                print(json.dumps({'name':tool['name'],'inputSchema':tool['inputSchema']}, ensure_ascii=False))
    else:
        opened = call('open_binary', {'path':r'D:\SteamLibrary\steamapps\common\Townscaper\GameAssembly.dll','provider_id':'ghidra'})
        (ROOT / 'work/rea_native_open.json').write_text(json.dumps(opened, ensure_ascii=False, indent=2), encoding='utf-8')
        print(json.dumps(opened, ensure_ascii=False)[:3500], flush=True)
        if 'error' not in opened:
            targets = ['0x103f7a90', '0x103f8420', '0x10e6b480', '0x10e73610']
            for address in targets:
                observation = call('analyze_function', {'procedure':address})
                (ROOT / f'work/rea_native_{address}.json').write_text(json.dumps(observation, ensure_ascii=False, indent=2), encoding='utf-8')
                print(json.dumps({'address':address, 'keys':list(observation), 'error':observation.get('error')}, ensure_ascii=False), flush=True)
                if 'error' in observation:
                    break
            print(json.dumps(call('export_evidence_bundle', {'path':str(output_path)}), ensure_ascii=False), flush=True)
        print(json.dumps(call('close_binary', {}), ensure_ascii=False)[:1200], flush=True)
finally:
    proc.stdin.close()
    proc.wait(timeout=30)
    log.close()
