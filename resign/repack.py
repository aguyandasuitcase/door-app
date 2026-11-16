"""repack.py ORIG.ipa SIGNED_TREE OUT.ipa
Rebuild the IPA with the same entries, order, dates and attributes as the
original. Only Mach-O files may differ; any other changed file aborts."""
import sys, os, zipfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import macho
orig, tree, out = sys.argv[1:4]
zi = zipfile.ZipFile(orig)
names = [i.filename for i in zi.infolist()]
with zipfile.ZipFile(out, 'w') as zo:
    for info in zi.infolist():
        if info.is_dir():
            zo.writestr(info, b''); continue
        old = zi.read(info.filename)
        path = os.path.join(tree, info.filename)
        new = open(path, 'rb').read()
        if new != old and not macho.is_macho(old):
            sys.exit('ABORT: non Mach-O file changed: ' + info.filename)
        ni = zipfile.ZipInfo(info.filename, info.date_time)
        ni.external_attr = info.external_attr
        ni.create_system = info.create_system
        ni.compress_type = zipfile.ZIP_DEFLATED
        zo.writestr(ni, new)
# nothing new may have appeared in the tree except what we removed
for root, _, files in os.walk(tree):
    for f in files:
        rel = os.path.relpath(os.path.join(root, f), tree)
        if rel not in names:
            print('note: not packed (not in original):', rel)
print('repacked', out)
