#!/usr/bin/env python3
"""Select a map and reload Hypr3D cleanly so its saved camera cannot leak maps."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import subprocess
import time

home=Path.home()
library=home/'Downloads/Hypr3D_Scenes'
state=home/'.config/hypr/hypr3d-scene'

def ctl(*args):
    return subprocess.check_output(['hyprctl',*args],text=True).strip()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('scene',nargs='?',default='list',help='list, next, prev, reset, or a scene ID')
    parser.add_argument('--quiet',action='store_true')
    args=parser.parse_args()
    scenes=json.loads((library/'manifest.json').read_text())['scenes']
    ids=[s['id'] for s in scenes]
    current=state.read_text().strip() if state.is_file() else 'cedar'
    if current not in ids: current=ids[0]
    if args.scene=='list':
        for s in scenes: print(('* ' if s['id']==current else '  ')+s['id']+' — '+s['label'])
        return
    runtime=Path(os.environ.get('XDG_RUNTIME_DIR','/tmp'))
    with (runtime/'hypr3d-scenes.lock').open('w') as lock:
        try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: return
        if args.scene in ['next','prev']:
            target=ids[(ids.index(current)+(1 if args.scene=='next' else -1))%len(ids)]
        elif args.scene=='reset': target=current
        else: target=args.scene
        if target not in ids: parser.error('Unknown scene: '+target)
        entry=scenes[ids.index(target)]
        if not Path(entry['path']).is_file(): parser.error('Missing map: '+entry['path'])
        plugin=Path('/etc/profiles/per-user')/home.name/'lib/hypr3d.so'
        if not plugin.is_file(): parser.error('The installed Hypr3D library is missing')
        # A false Lua assertion is hyprctl exit 7, the normal closed-3D case.
        probe=subprocess.run(['hyprctl','eval','assert(hl.plugin.hypr3d and hl.plugin.hypr3d.active())'],
                             text=True,capture_output=True)
        if probe.returncode not in [0,7]:
            raise RuntimeError(probe.stdout+probe.stderr)
        active=probe.returncode==0 and probe.stdout.strip()=='ok'
        if active:
            ctl('eval','hl.plugin.hypr3d.close()')
            time.sleep(.8)
        tmp=state.with_suffix('.tmp')
        tmp.write_text(target+'\n')
        tmp.replace(state)
        try:
            result=ctl('plugin','unload',str(plugin))
            if result!='ok': raise RuntimeError(result)
            result=ctl('plugin','load',str(plugin))
            if result!='ok': raise RuntimeError(result)
            ctl('reload')
            errors=ctl('configerrors')
            if errors: raise RuntimeError(errors)
            if active: ctl('eval','hl.plugin.hypr3d.open()')
        except Exception:
            state.write_text(current+'\n')
            ctl('plugin','load',str(plugin))
            ctl('reload')
            raise
        if not args.quiet:
            ctl('notify','1','3000','rgb(9ac6af)','Hypr3D: '+entry['label'])
        print('Selected:',entry['id'],'—',entry['label'])

if __name__=='__main__': main()
