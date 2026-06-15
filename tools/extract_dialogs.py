#!/usr/bin/env python3
"""Parse DGDS DDS dialog files (The Adventures of Willy Beamish, ver " 1.224")
and extract dialogue. Faithful port of ScummVM engines/dgds/scene.cpp
SDSScene::loadDialogData + Scene::readDialogList.

UNLIKE Rise of the Dragon (SDS ver 1.211, dialogs embedded in the scene),
Willy Beamish (ver 1.224) stores dialogue in separate D<N>.DDS files, loaded
on demand via scene ops. The dialog list is keyed by (ddsFileNum, num).

Version predicates are computed dynamically from each file's own version
string (mirrors strncmp(_version, v, _version.size()) in Scene::isVersionOver
/isVersionUnder), so this tool works for any DGDS dialog version.
"""
import sys, os, struct, json, glob, re
sys.path.insert(0, os.path.dirname(__file__))
from dgds_chunks import iter_chunks, decompress_blob


class Ver:
    """Replicates Scene::isVersionOver / isVersionUnder (strncmp, len=_version.size())."""
    def __init__(self, v): self.v = v
    def over(self, other):   # _version > other
        n = len(self.v)
        return self.v[:n] > other[:n]
    def under(self, other):  # _version < other
        n = len(self.v)
        return self.v[:n] < other[:n]


class R:
    def __init__(self, data): self.d = data; self.p = 0
    def u16(self):
        v = struct.unpack_from('<H', self.d, self.p)[0]; self.p += 2; return v
    def s16(self):
        v = struct.unpack_from('<h', self.d, self.p)[0]; self.p += 2; return v
    def u32(self):
        v = struct.unpack_from('<I', self.d, self.p)[0]; self.p += 4; return v
    def cstr(self):
        e = self.d.index(b'\0', self.p); s = self.d[self.p:e]; self.p = e + 1
        return s.decode('latin1')
    def fixedstr(self, n):
        raw = self.d[self.p:self.p + n]; self.p += n
        z = raw.find(b'\0')
        return (raw if z < 0 else raw[:z]).decode('cp437')
    def rem(self): return len(self.d) - self.p


def read_condlist(r):
    num = r.u16()
    for _ in range(num):
        r.u16(); r.u16(); r.s16()


def read_oplist(r):
    n = r.u16()
    for _ in range(n):
        read_condlist(r)
        r.u16()                 # opCode
        nvals = r.u16()
        for _ in range(nvals // 2):
            r.u16()


def read_dialogactionlist(r):
    n = r.u16()
    for _ in range(n):
        r.u16(); r.u16()        # strStart, strEnd
        read_oplist(r)


def read_dialoglist(r, ver, out, filenum):
    nitems = r.u16()
    for _ in range(nitems):
        num = r.u16()
        rx, ry, rw, rh = r.u16(), r.u16(), r.u16(), r.u16()
        bg = r.u16(); fg = r.u16()
        if ver.under(" 1.209"):
            selbg, selfg = bg, fg
        else:
            selbg = r.u16(); selfg = r.u16()
        fontsize = r.u16()
        if ver.under(" 1.210"):
            r.u16()             # flags (u16)
        else:
            r.u32()             # flags (u32, truncated to u16 by engine)
        r.u16()                 # frameType
        r.u16()                 # time
        if ver.over(" 1.215"):
            r.u16()             # nextDialogFileNum
        if ver.over(" 1.207"):
            r.u16()             # nextDialogDlgNum
        if ver.over(" 1.216"):
            r.u16(); r.u16()    # talkDataNum, talkDataHeadNum
        nbytes = r.u16()
        s = ""
        if nbytes > 0:
            s = r.fixedstr(nbytes)
        read_dialogactionlist(r)
        if s:
            out.append(dict(file=filenum, num=num, rect=[rx, ry, rw, rh],
                            bg=bg, fg=fg, fontsize=fontsize, text=s))


def _filenum(path):
    m = re.match(r'd(\d+)\.dds$', os.path.basename(path), re.I)
    return int(m.group(1)) if m else 0


def parse_dds(path):
    """Return (dialogs, version, fileId) for one D<N>.DDS file."""
    data = open(path, 'rb').read()
    filenum = _filenum(path)
    dialogs = []
    version = None; fileid = None
    for idstr, size, cont, start, payload in iter_chunks(data):
        if idstr == 'DDS:' and not cont:
            raw = decompress_blob(payload)
            r = R(raw)
            r.u32()                     # magic
            version = r.cstr()          # e.g. " 1.224"
            fileid = r.cstr()           # e.g. "CS CLASSROOM"
            ver = Ver(version)
            read_dialoglist(r, ver, dialogs, filenum)
            return dialogs, version, fileid
    return dialogs, version, fileid


def main():
    indir = sys.argv[1]
    files = sorted(glob.glob(os.path.join(indir, '*.dds')), key=_filenum)
    alldlg = []; bad = 0; versions = set(); labels = {}
    for f in files:
        try:
            dlg, ver, fid = parse_dds(f)
            alldlg += dlg
            if ver: versions.add(ver)
            if fid is not None:
                labels[_filenum(f)] = fid
        except Exception as e:
            print(f"FAIL {os.path.basename(f)}: {e}", file=sys.stderr); bad += 1
    print(f"# {len(files)} DDS files, {len(alldlg)} dialogs, {bad} parse failures, "
          f"versions={sorted(versions)}", file=sys.stderr)
    if len(sys.argv) > 2:
        json.dump(alldlg, open(sys.argv[2], 'w'), ensure_ascii=False, indent=1)
        print(f"# wrote {sys.argv[2]}", file=sys.stderr)
        lbl_path = os.path.splitext(sys.argv[2])[0] + '_labels.json'
        json.dump({str(k): v for k, v in sorted(labels.items())},
                  open(lbl_path, 'w'), ensure_ascii=False, indent=1)
        print(f"# wrote {lbl_path}", file=sys.stderr)


if __name__ == '__main__':
    main()
