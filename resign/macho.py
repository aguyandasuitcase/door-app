"""Minimal Mach-O inspection (fat + thin, 32/64-bit). No external deps."""
import struct
LC_SEGMENT, LC_SEGMENT_64, LC_CODE_SIGNATURE = 0x1, 0x19, 0x1d
LC_ENCRYPTION_INFO, LC_ENCRYPTION_INFO_64 = 0x21, 0x2c
THIN = (0xfeedface, 0xfeedfacf)

def is_macho(d):
    if len(d) < 8: return False
    m = struct.unpack_from('<I', d, 0)[0]
    return m in THIN or struct.unpack_from('>I', d, 0)[0] == 0xcafebabe

def slices(d):
    if struct.unpack_from('>I', d, 0)[0] == 0xcafebabe:
        n = struct.unpack_from('>I', d, 4)[0]
        out = []
        for i in range(n):
            cpu, sub, off, size, al = struct.unpack_from('>iiIII', d, 8 + 20 * i)
            out.append((off, size))
        return out
    return [(0, len(d))]

def parse(d, off):
    magic = struct.unpack_from('<I', d, off)[0]
    is64 = magic == 0xfeedfacf
    hdr = 32 if is64 else 28
    cpu, sub, ft, ncmds, sizeofcmds, flags = struct.unpack_from('<iiIIII', d, off + 4)
    p = off + hdr
    info = dict(cpu=cpu & 0xffffffff, ncmds=ncmds, sizeofcmds=sizeofcmds, sig=None,
                cryptid=None, linkedit=None, min_sect=None, is64=is64)
    for _ in range(ncmds):
        cmd, cs = struct.unpack_from('<II', d, p)
        if cmd == LC_CODE_SIGNATURE:
            info['sig'] = struct.unpack_from('<II', d, p + 8)
        elif cmd in (LC_ENCRYPTION_INFO, LC_ENCRYPTION_INFO_64):
            info['cryptid'] = struct.unpack_from('<I', d, p + 8 + 8)[0]
        elif cmd in (LC_SEGMENT, LC_SEGMENT_64):
            seg64 = cmd == LC_SEGMENT_64
            name = d[p + 8:p + 24].split(b'\0')[0]
            if seg64:
                fileoff, filesize = struct.unpack_from('<QQ', d, p + 40)
                nsects = struct.unpack_from('<I', d, p + 64)[0]; sp = p + 72; so = 48; ss = 80
            else:
                fileoff, filesize = struct.unpack_from('<II', d, p + 32)
                nsects = struct.unpack_from('<I', d, p + 48)[0]; sp = p + 56; so = 40; ss = 68
            if name == b'__LINKEDIT':
                info['linkedit'] = (fileoff, filesize)
            for i in range(nsects):
                soff = struct.unpack_from('<I', d, sp + i * ss + so)[0]
                if soff and (info['min_sect'] is None or soff < info['min_sect']):
                    info['min_sect'] = soff
        p += cs
    return info

def sig_kind(d, off, sig):
    """Return (blob_magic_ok, adhoc, has_cms) for the embedded signature."""
    base = off + sig[0]
    magic, length, count = struct.unpack_from('>III', d, base)
    slots = {}
    for i in range(count):
        t, o = struct.unpack_from('>II', d, base + 12 + 8 * i)
        slots[t] = o
    cd = base + slots.get(0, 0)
    flags = struct.unpack_from('>I', d, cd + 12)[0]
    # an ad-hoc signature carries an empty CMS slot (8 byte blob); a real one is larger
    cms = False
    if 0x10000 in slots:
        cms = struct.unpack_from('>I', d, base + slots[0x10000] + 4)[0] > 8
    return magic == 0xfade0cc0, bool(flags & 2), cms
