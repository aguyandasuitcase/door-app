"""verify.py ORIG.ipa NEW.ipa  -> exit 1 on any failure"""
import sys, os, zipfile, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import macho
o, n = zipfile.ZipFile(sys.argv[1]), zipfile.ZipFile(sys.argv[2])
fail = []
def chk(ok, msg):
    print(('PASS ' if ok else 'FAIL ') + msg)
    if not ok: fail.append(msg)
on, nn = [i.filename for i in o.infolist()], [i.filename for i in n.infolist()]
chk(on == nn, 'same entry names and order (%d entries)' % len(nn))
chk(not any('_CodeSignature' in x or x.endswith('embedded.mobileprovision') for x in nn),
    'no _CodeSignature folder, no embedded.mobileprovision')
for name in nn:
    if name.endswith('/'): continue
    od, nd = o.read(name), n.read(name)
    if not macho.is_macho(nd):
        chk(od == nd, 'identical: ' + name + ('  sha256 ' + hashlib.sha256(nd).hexdigest()[:16] if name.endswith('Info.plist') else ''))
        continue
    os_, ns_ = macho.slices(od), macho.slices(nd)
    chk(len(os_) == len(ns_), 'Mach-O %s: %d slice(s)' % (name, len(ns_)))
    for (oo, osz), (no, nsz) in zip(os_, ns_):
        a, b = macho.parse(od, oo), macho.parse(nd, no)
        tag = '%s cpu=%#x' % (name, b['cpu'])
        chk(a['sig'] is None, tag + ' original had no LC_CODE_SIGNATURE')
        chk(b['sig'] is not None, tag + ' LC_CODE_SIGNATURE present')
        if b['sig']:
            ok, adhoc, cms = macho.sig_kind(nd, no, b['sig'])
            chk(ok and adhoc and not cms, tag + ' signature is plain ad-hoc (no CMS/identity)')
            chk(b['sig'][0] + b['sig'][1] <= nsz, tag + ' signature lies inside slice')
        chk(b['cryptid'] in (0, None), tag + ' not encrypted (cryptid=%s)' % b['cryptid'])
        lo = b['linkedit'][0]
        same = od[oo + a['min_sect']:oo + a['linkedit'][0]] == nd[no + b['min_sect']:no + lo]
        chk(a['min_sect'] == b['min_sect'] and same, tag + ' code and data (section start to __LINKEDIT) byte-identical')
        olink = od[oo + a['linkedit'][0]:oo + a['linkedit'][0] + a['linkedit'][1]]
        nlink = nd[no + lo:no + lo + len(olink)]
        print('INFO ' + tag + ' __LINKEDIT original content preserved as prefix: ' + str(olink == nlink))
sys.exit(1 if fail else 0)
