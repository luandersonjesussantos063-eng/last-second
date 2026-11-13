"""Build a test variant of the supplied LN3D3V map; never edits the input ZIP.

Layout references: CodeWalker Meta.cs, MetaTypes.cs and YmapFile.cs.
This validates binary structure, not GTA runtime behavior.
"""
import hashlib
import json
from pathlib import Path
import struct
import sys
import zipfile
import zlib

EXPECTED = '63290728ebef874bed188d74f7c6a3918e1e2b148a236dea2d42b4cebee17fcf'
BASE = 0x50000000
MLO_TYPE = 164374718


def unpack(data, fmt, offset):
    return struct.unpack_from('<' + fmt, data, offset)


def blocks(data):
    table = unpack(data, 'Q', 0x30)[0] - BASE
    count = unpack(data, 'H', 0x4C)[0]
    result = [unpack(data, 'IIQ', table + i * 16) for i in range(count)]
    for _, size, pointer in result:
        assert 0 <= pointer - BASE <= len(data) - size
    return result


def address(entries, pointer, size=1):
    block = entries[(pointer & 0xFFF) - 1]
    offset = (pointer >> 12) & 0xFFFFF
    assert 0 <= offset <= block[1] - size
    return block[2] - BASE + offset


def decode(data):
    assert data[:4] == b'RSC7'
    return bytearray(zlib.decompress(data[16:], -15))


def encode(header, data):
    compressor = zlib.compressobj(9, zlib.DEFLATED, -15)
    result = header[:16] + compressor.compress(data) + compressor.flush()
    assert decode(result) == data
    return result


def embed_collision(drawable, collision):
    """Keep the drawable and copy its supplied collision into the YDR system page."""
    mesh = decode(drawable)
    bound = decode(collision)
    assert unpack(drawable, 'I', 12)[0] == 0x50000000, 'Unexpected graphics pages'
    assert unpack(mesh, 'Q', 0xC8)[0] == 0
    offset = (len(mesh) + 15) & ~15
    moved = []
    for at in range(0, len(bound)-7, 8):
        value = unpack(bound, 'Q', at)[0]
        if BASE <= value < BASE+len(bound):
            struct.pack_into('<Q', bound, at, value+offset)
            moved.append(at)
    assert len(moved) >= 10
    mesh += bytes(offset-len(mesh)) + bound
    assert len(mesh) < 65536
    mesh += bytes(65536-len(mesh))
    struct.pack_into('<Q', mesh, 0xC8, BASE+offset)
    pages = unpack(mesh, 'Q', 8)[0]-BASE
    mesh[pages+8:pages+10] = bytes([1, 0])
    header = bytearray(drawable[:16])
    struct.pack_into('<I', header, 8, 0xA0000020)  # one 64 KiB system page, type A
    for at in moved:
        pointer = unpack(mesh, 'Q', offset+at)[0]
        assert BASE+offset <= pointer < BASE+offset+len(bound)
    return encode(header, mesh)


def build(source, destination):
    original = Path(source).read_bytes()
    assert hashlib.sha256(original).hexdigest() == EXPECTED, 'Unexpected source ZIP'
    destination = Path(destination)
    destination.mkdir(parents=True, exist_ok=True)
    files = {}
    with zipfile.ZipFile(source) as archive:
        assert archive.testzip() is None
        for item in archive.infolist():
            if not item.is_dir():
                files[item.filename] = archive.read(item)
    prefix = 'prfMiniLN3d3v/stream/'
    map_name = prefix + 'prfminibaseln3d3v.ymap'
    type_name = prefix + 'PRFMLOMINIBASE3D3V.ytyp'
    raw = decode(files[map_name])
    entries = blocks(raw)
    assert len(raw) == 8192 and len(entries) == 4
    root = entries[0][2] - BASE
    array_ptr, count, capacity = unpack(raw, 'QHH', root + 96)
    assert count == capacity == 8
    pointers = address(entries, array_ptr, count * 8)
    old_ref = unpack(raw, 'Q', pointers + 8)[0]
    old_entity = address(entries, old_ref, 128)
    assert unpack(raw, 'I', old_entity + 8)[0] == 0x9D057B2B
    # This schema is already present in the source, but no block uses it.
    schema = unpack(raw, 'Q', 0x20)[0] - BASE
    schemas = [unpack(raw, 'III', schema + i * 32)
               for i in range(unpack(raw, 'H', 0x48)[0])]
    assert (MLO_TYPE, 2151576752, 1024) in schemas
    # Use only verified zero padding; resource page flags/size remain unchanged.
    instance_at, table_at = 0x1F10, 0x1FB0
    assert not any(raw[instance_at:])
    instance = bytearray(raw[old_entity:old_entity + 128] + bytes(32))
    struct.pack_into('<I', instance, 152, 3)  # Three portals to exterior room 0.
    raw[instance_at:instance_at + 160] = instance
    entries.append((MLO_TYPE, 160, BASE + instance_at))
    for i, entry in enumerate(entries):
        struct.pack_into('<IIQ', raw, table_at + i * 16, *entry)
    struct.pack_into('<Q', raw, 0x30, BASE + table_at)
    struct.pack_into('<H', raw, 0x4C, len(entries))
    struct.pack_into('<Q', raw, pointers + 8, 5)  # Block 5, offset 0.
    flags = unpack(raw, 'I', root + 20)[0]
    struct.pack_into('<I', raw, root + 20, flags | 8)  # Interior instance present.
    assert len(raw) == 8192
    verified = blocks(raw)
    refs = [unpack(raw, 'Q', pointers + i * 8)[0] for i in range(count)]
    assert sum(verified[(ref & 0xFFF) - 1][0] == MLO_TYPE for ref in refs) == 1
    for ref in refs:
        address(verified, ref, 160 if ref == 5 else 128)
    files[map_name] = encode(files[map_name], raw)
    # The child drawable and both room bounds agree. Use its actual bounds,
    # centre and sphere rather than the original all-zero MLO bounds.
    drawable = decode(files[prefix + 'prfmlo.ydr'])
    types = decode(files[type_name])
    type_blocks = blocks(types)
    mlo = next(p - BASE for h, size, p in type_blocks if h == 273704021)
    assert not any(types[mlo + 32:mlo + 84])
    types[mlo + 32:mlo + 44] = drawable[0x30:0x3C]
    types[mlo + 48:mlo + 60] = drawable[0x40:0x4C]
    types[mlo + 64:mlo + 76] = drawable[0x20:0x2C]
    types[mlo + 80:mlo + 84] = drawable[0x2C:0x30]
    assert unpack(types, 'f', mlo + 80)[0] > 0
    files[type_name] = encode(files[type_name], types)
    # The supplied interior YDR has no embedded collision, and its archetype
    # never registers the separate prfmlo.model collision. Bind the exact source
    # collision to the drawable rather than substituting invisible wall boxes.
    files[prefix+'prfmlo.ydr'] = embed_collision(files[prefix+'prfmlo.ydr'],files[prefix+'prfmlo.model.ybn'])
    types = decode(files[type_name])
    archetype = next(p-BASE for h,size,p in blocks(types) if h==2195127427)
    struct.pack_into('<I',types,archetype+104,unpack(types,'I',archetype+88)[0])
    child = next(p-BASE for h,size,p in blocks(types) if h==3461354627)
    struct.pack_into('<I',types,child+12,unpack(types,'I',child+12)[0] | 32)
    files[type_name] = encode(files[type_name],types)
    files['prfMiniLN3d3v/fxmanifest.lua'] = (
        "fx_version 'cerulean'\ngame 'gta5'\nthis_is_a_map 'yes'\n"
        "version '1.0.2-collision-test'\n\n"
        "data_file 'DLC_ITYP_REQUEST' 'stream/YTYPPRFln3d3v.ytyp'\n"
        "data_file 'DLC_ITYP_REQUEST' 'stream/PRFMLOMINIBASE3D3V.ytyp'\n\n"
        "dependency '/assetpacks'\n").encode()
    report = {
        'status': 'interior-restored-test-not-validated-in-game',
        'original_zip_sha256': EXPECTED,
        'entities': 8, 'ordinary_entities': 7, 'mlo_instances': 1,
        'exit_portals': 3,
        'changes': ['CMloInstanceDef block and pointer', 'interior content flag',
                    'MLO bounds copied from child drawable', 'explicit YTYP registration',
                    'source collision embedded in interior YDR', 'interior physics dictionary registered'],
        'file_sha256': {name: hashlib.sha256(data).hexdigest()
                        for name, data in files.items()},
    }
    files['audit.json'] = json.dumps(report, indent=2).encode()
    files['LEIA-ME.txt'] = (
        'VERSAO DE TESTE COM INTERIOR RESTAURADO. Ainda requer teste no FiveM.\n'
        'Pare o servidor. Mova a versao anterior da pasta prfMiniLN3d3v para FORA '
        'de resources. Extraia esta pasta em resources/[prf]. Mantenha so uma copia '
        'ativa. Inicie o servidor, feche e reabra o FiveM e teste a mesma estrada.\n'
        'Se voltar a travar, pare o mapa e volte ao pacote exterior de diagnostico.\n'
        'Creditos: LN3D3V. Preserve condicoes de uso e autoria originais. '
        'Dependencia /assetpacks preservada.\n').encode()
    output = destination / 'PRF-Base-Interior-Teste.zip'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name, data in files.items():
            info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert len(archive.namelist()) == 15
    print(json.dumps({'zip': str(output), 'bytes': output.stat().st_size,
                      'sha256': hashlib.sha256(output.read_bytes()).hexdigest()}))


if __name__ == '__main__':
    build(sys.argv[1], sys.argv[2])
