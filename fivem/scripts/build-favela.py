"""Convert the supplied Map Editor XML into addon YMAP/YTYP assets for FiveM.

Requires the original favela ZIP and the original PRF map ZIP as a Meta schema
template. Source archives are read as data; no supplied code is executed.
"""
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import xml.etree.ElementTree as ET
import zipfile
import zlib

BASE = 0x50000000


def joaat(value):
    result = 0
    for char in value.lower().encode():
        result = (result + char) & 0xFFFFFFFF
        result = (result + (result << 10)) & 0xFFFFFFFF
        result ^= result >> 6
    result = (result + (result << 3)) & 0xFFFFFFFF
    result ^= result >> 11
    return (result + (result << 15)) & 0xFFFFFFFF


def raw(data):
    assert data[:4] == b'RSC7'
    return bytearray(zlib.decompress(data[16:], -15))


def blocks(data):
    table = struct.unpack_from('<Q', data, 0x30)[0] - BASE
    return [struct.unpack_from('<IIQ', data, table+i*16)
            for i in range(struct.unpack_from('<H', data, 0x4C)[0])]


def pack_resource(header, data):
    size = 8192
    while size < len(data):
        size *= 2
    shifts = {8192: 27, 16384: 26, 32768: 25, 65536: 24,
              131072: 17, 262144: 11, 524288: 7, 1048576: 5, 2097152: 4}
    assert size in shifts
    data += bytes(size-len(data))
    head = bytearray(header[:16])
    struct.pack_into('<I', head, 8, (1 << shifts[size]) | 4)
    compress = zlib.compressobj(9, zlib.DEFLATED, -15)
    result = bytes(head) + compress.compress(data) + compress.flush()
    assert raw(result) == data
    return result


def meta(template, payloads):
    result = raw(template)
    # Keep template schemas/enums; create fresh root/data blocks after them.
    result += bytes((-len(result)) % 16)
    entries = []
    for type_hash, payload in payloads:
        at = len(result)
        entries.append((type_hash, len(payload), BASE+at))
        result.extend(payload)
        result.extend(bytes((-len(result)) % 16))
    table = len(result)
    for entry in entries:
        result.extend(struct.pack('<IIQ', *entry))
    struct.pack_into('<Q', result, 0x30, BASE+table)
    struct.pack_into('<H', result, 0x4C, len(entries))
    output = pack_resource(template, result)
    parsed = raw(output)
    for _, length, pointer in blocks(parsed):
        assert 0 <= pointer-BASE <= len(parsed)-length
    return output


def rotate(point, q):
    x, y, z, w = q
    tx = 2*(y*point[2]-z*point[1])
    ty = 2*(z*point[0]-x*point[2])
    tz = 2*(x*point[1]-y*point[0])
    return (point[0]+w*tx+y*tz-z*ty,
            point[1]+w*ty+z*tx-x*tz,
            point[2]+w*tz+x*ty-y*tx)


def build(favela_zip, map_zip, output):
    output = Path(output)
    stream = output/'stream'
    stream.mkdir(parents=True, exist_ok=True)
    source = zipfile.ZipFile(favela_zip)
    template = zipfile.ZipFile(map_zip)
    assert source.testzip() is None and template.testzip() is None
    xml_name = next(n for n in source.namelist() if n.lower().endswith('.xml'))
    scene = ET.fromstring(source.read(xml_name))
    objects = scene.findall('./Objects/MapObject')
    models = {}
    metadata = []
    for name in source.namelist():
        if not name.lower().endswith('.ydr'):
            continue
        original_name = Path(name).stem.lower()
        new_name = 'prffavela_'+original_name
        data = source.read(name)
        decoded = raw(data)
        assert struct.unpack_from('<I', data, 4)[0] == 165
        lo, hi = struct.unpack_from('<3f', decoded, 0x30), struct.unpack_from('<3f', decoded, 0x40)
        assert all(math.isfinite(v) for v in lo+hi) and all(a < b for a, b in zip(lo, hi))
        assert struct.unpack_from('<Q', decoded, 0xC8)[0] != 0, 'Missing model collision: '+name
        record = bytearray(144)
        struct.pack_into('<f', record, 8, 250.0)
        struct.pack_into('<3f', record, 32, *lo)
        struct.pack_into('<3f', record, 48, *hi)
        struct.pack_into('<3f', record, 64, *struct.unpack_from('<3f', decoded, 0x20))
        struct.pack_into('<f', record, 80, struct.unpack_from('<f', decoded, 0x2C)[0])
        struct.pack_into('<f', record, 84, 40.0)
        new_hash = joaat(new_name)
        texture = new_hash if original_name == 'hei_prop_hei_keypad_01' else 0
        struct.pack_into('<7I', record, 88, new_hash, texture, 0, 0, 0, 2, new_hash)
        (stream/(new_name+'.ydr')).write_bytes(data)
        models[joaat(original_name)] = {'hash': new_hash, 'record': record, 'lo': lo, 'hi': hi}
        metadata.append({'source': name, 'file': new_name+'.ydr', 'sha256': hashlib.sha256(data).hexdigest()})
    for name in source.namelist():
        if name.lower().endswith('.ytd'):
            data = source.read(name)
            new_name = 'prffavela_'+Path(name).name.lower()
            (stream/new_name).write_bytes(data)
            metadata.append({'source': name, 'file': new_name, 'sha256': hashlib.sha256(data).hexdigest()})
    # Archetype list: 15 renamed addons, not replacements of GTA heist props.
    typ_template = template.read('prfMiniLN3d3v/stream/YTYPPRFln3d3v.ytyp')
    typ_data = raw(typ_template)
    root_at = blocks(typ_data)[0][2]-BASE
    root = bytearray(typ_data[root_at:root_at+80])
    root[8:80] = bytes(72)
    struct.pack_into('<QHH', root, 24, 3, len(models), len(models))
    struct.pack_into('<I', root, 40, joaat('prf_favela_assets'))
    records = b''.join(m['record'] for m in models.values())
    pointers = b''.join(struct.pack('<Q', (i*144 << 12)|2) for i in range(len(models)))
    (stream/'prf_favela_assets.ytyp').write_bytes(meta(typ_template,
        [(3649811809, root), (2195127427, records), (7, pointers)]))
    map_template = template.read('prfMiniLN3d3v/stream/prfminibaseln3d3v.ymap')
    old = raw(map_template)
    root_at = blocks(old)[0][2]-BASE
    root = bytearray(old[root_at:root_at+512])
    root[8:] = bytes(504)
    struct.pack_into('<4I', root, 8, joaat('prf_favela_realista'), 0, 0, 1)
    records = bytearray()
    world_points, gang_points, sectors = [], [], {}
    for obj in objects:
        kind = obj.findtext('Type')
        position = tuple(float(obj.findtext('Position/'+k)) for k in 'XYZ')
        if kind == 'Ped':
            gang_points.append({'x': position[0], 'y': position[1], 'z': position[2],
                                'heading': float(obj.findtext('Rotation/Z', '0'))})
        if kind != 'Prop':
            continue
        model_hash = int(obj.findtext('Hash')) & 0xFFFFFFFF
        model = models.get(model_hash)
        q = tuple(float(obj.findtext('Quaternion/'+k)) for k in 'XYZW')
        norm = math.sqrt(sum(v*v for v in q))
        assert norm > 0.5 and all(math.isfinite(v) for v in position+q)
        q = tuple(v/norm for v in q)
        record = bytearray(128)
        struct.pack_into('<II', record, 8, model['hash'] if model else model_hash, 32)
        struct.pack_into('<3f', record, 32, *position)
        struct.pack_into('<4f', record, 48, -q[0], -q[1], -q[2], q[3])
        struct.pack_into('<2fiffIII', record, 64, 1.0, 1.0, -1, 250.0 if model else 150.0, 0.0, 5, 0, 0)
        struct.pack_into('<2I', record, 112, 255, 255)
        records.extend(record)
        cell = (math.floor(position[0]/300), math.floor(position[1]/300))
        sector = sectors.setdefault(cell, {'records': bytearray(), 'points': []})
        sector['records'].extend(record)
        lo, hi = (model['lo'], model['hi']) if model else ((-50,-50,-50), (50,50,50))
        for x in [lo[0],hi[0]]:
            for y in [lo[1],hi[1]]:
                for z in [lo[2],hi[2]]:
                    v = rotate((x,y,z),q)
                    point = tuple(position[i]+v[i] for i in range(3))
                    world_points.append(point)
                    sector['points'].append(point)
    count = len(records)//128
    assert count == 495 and len(models) == 15 and len(gang_points) == 64
    lo = tuple(min(p[i] for p in world_points) for i in range(3))
    hi = tuple(max(p[i] for p in world_points) for i in range(3))
    for previous in stream.glob('prf_favela_realista*.ymap'):
        previous.unlink()
    for (cx, cy), sector in sorted(sectors.items()):
        name = 'prf_favela_realista_'+('p' if cx>=0 else 'm')+str(abs(cx))+'_'+('p' if cy>=0 else 'm')+str(abs(cy))
        local_root = bytearray(root)
        struct.pack_into('<I', local_root, 8, joaat(name))
        low = tuple(min(p[i] for p in sector['points']) for i in range(3))
        high = tuple(max(p[i] for p in sector['points']) for i in range(3))
        struct.pack_into('<3f', local_root, 32, *(v-250 for v in low))
        struct.pack_into('<3f', local_root, 48, *(v+250 for v in high))
        struct.pack_into('<3f', local_root, 64, *low)
        struct.pack_into('<3f', local_root, 80, *high)
        local_count = len(sector['records'])//128
        struct.pack_into('<QHH', local_root, 96, 3, local_count, local_count)
        pointers = b''.join(struct.pack('<Q', (i*128 << 12)|2) for i in range(local_count))
        (stream/(name+'.ymap')).write_bytes(meta(map_template,
            [(3545841574, local_root), (3461354627, sector['records']), (7, pointers)]))
    # The source has a lone NPC far from the favela. Keep its dense gang cluster.
    def distance(a,b):
        return (a['x']-b['x'])**2+(a['y']-b['y'])**2+(a['z']-b['z'])**2
    center = max(gang_points, key=lambda p:sum(distance(p,q)<400**2 for q in gang_points))
    gang_points = [p for p in gang_points if distance(p,center)<400**2]
    (output/'gang_points.lua').write_text('FavelaPoints = '+
        '{\n'+''.join('  { x = %.6f, y = %.6f, z = %.6f, heading = %.6f },\n' %
                    (p['x'],p['y'],p['z'],p['heading']) for p in gang_points)+'}\n')
    (output/'fxmanifest.lua').write_text(
        "fx_version 'cerulean'\ngame 'gta5'\nthis_is_a_map 'yes'\nversion '1.0.0-test'\n"
        "data_file 'DLC_ITYP_REQUEST' 'stream/prf_favela_assets.ytyp'\n"
        "client_scripts { 'gang_points.lua', 'gangs_client.lua' }\n")
    report = {'status': 'converted-not-validated-in-game', 'props': count,
              'custom_addon_models': len(models), 'original_ped_positions': 64,
              'gang_slots_in_favela': len(gang_points), 'streaming_sectors': len(sectors),
              'active_gang_limit': 12, 'original_vehicles_and_pickup_not_spawned': True,
              'source_archive_sha256': hashlib.sha256(Path(favela_zip).read_bytes()).hexdigest(),
              'files': metadata, 'world_bounds': {'min': lo, 'max': hi}}
    (output/'origem.json').write_text(json.dumps(report,indent=2))
    print(json.dumps({'resource':str(output),'props':count,'addons':len(models),'gang_slots':len(gang_points)}))


if __name__ == '__main__':
    build(*sys.argv[1:])
