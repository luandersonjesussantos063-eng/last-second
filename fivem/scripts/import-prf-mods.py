#!/usr/bin/env python3
"""Importa somente os binários conhecidos dos mods enviados, sem executar mods."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
import tempfile
import zipfile


RESOURCES = Path(__file__).resolve().parents[1] / "resources" / "[prf]"
MAX_FILE_BYTES = 128 * 1024 * 1024


def safe_name(name):
    name = str(name).replace("\\", "/")
    path = PurePosixPath(name)
    if path.is_absolute() or ".." in path.parts or ":" in name or "\0" in name:
        raise ValueError(f"Caminho inseguro no pacote: {name!r}")
    return path.as_posix()


def matches_suffix(candidate, expected):
    candidate = safe_name(candidate)
    return candidate == expected or candidate.endswith("/" + expected)


def read_directory(source, expected, expected_size):
    candidates = []
    for path in source.rglob(PurePosixPath(expected).name):
        if matches_suffix(path.relative_to(source).as_posix(), expected):
            if path.is_symlink() or not path.resolve().is_relative_to(source):
                raise ValueError(f"Link nao permitido: {path}")
            if path.is_file():
                candidates.append(path)
    if len(candidates) != 1:
        raise ValueError(f"Esperado um unico arquivo {expected}; encontrados {len(candidates)}.")
    path = candidates[0]
    if path.stat().st_size != expected_size:
        raise ValueError(f"Tamanho diferente do pacote registrado: {path.name}")
    return path.read_bytes()


def read_zip(source, expected, expected_size):
    with zipfile.ZipFile(source) as archive:
        candidates = [entry for entry in archive.infolist()
                      if not entry.is_dir() and matches_suffix(entry.filename, expected)]
        if len(candidates) != 1:
            raise ValueError(f"Esperado um unico arquivo {expected} no ZIP; encontrados {len(candidates)}.")
        entry = candidates[0]
        if (entry.external_attr >> 16) & 0o170000 == 0o120000:
            raise ValueError(f"Link nao permitido no ZIP: {entry.filename}")
        if entry.file_size != expected_size:
            raise ValueError(f"Tamanho diferente do pacote registrado: {entry.filename}")
        with archive.open(entry) as handle:
            return handle.read(expected_size + 1)


def read_rar(source, expected, expected_size):
    # Saida binaria vai para memoria, nunca para caminhos fornecidos pelo RAR.
    # Somente nomes exatos da allowlist sao solicitados ao extrator instalado.
    if shutil.which("7z"):
        command = ["7z", "x", "-so", "-bsp0", str(source), expected]
    elif shutil.which("unrar"):
        command = ["unrar", "p", "-inul", str(source), expected]
    elif shutil.which("bsdtar"):
        command = ["bsdtar", "-xOf", str(source), expected]
    else:
        raise ValueError("Para ler RAR, instale 7z, unrar ou bsdtar; ou extraia manualmente "
                         "o pacote e informe a pasta extraida. Nenhum programa sera instalado automaticamente.")
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as process:
        data = process.stdout.read(expected_size + 1)
        if len(data) > expected_size:
            process.kill()
            raise ValueError(f"Arquivo maior que o tamanho registrado: {expected}")
        if process.wait() != 0:
            raise ValueError(f"Nao foi possivel ler {expected} no RAR. Extraia manualmente e informe a pasta.")
    return data


def import_resource(source, resource_name):
    source = source.expanduser().resolve()
    if not source.exists():
        raise ValueError(f"Pacote/pasta nao encontrado: {source}")
    resource = RESOURCES / resource_name
    metadata = json.loads((resource / "origem.json").read_text(encoding="utf-8"))
    prepared = []
    for entry in metadata["files"]:
        expected = safe_name(entry["source"])
        destination = safe_name(entry["destination"])
        if not destination.startswith("stream/") or Path(destination).suffix.lower() not in {
            ".yft", ".ytd", ".ydd"
        }:
            raise ValueError(f"Destino fora da allowlist de assets: {destination}")
        expected_size = entry["bytes"]
        if not 0 < expected_size <= MAX_FILE_BYTES:
            raise ValueError(f"Tamanho fora do limite: {expected}")
        if source.is_dir():
            data = read_directory(source, expected, expected_size)
        elif source.suffix.lower() == ".zip":
            data = read_zip(source, expected, expected_size)
        elif source.suffix.lower() == ".rar":
            data = read_rar(source, expected, expected_size)
        else:
            raise ValueError("Informe uma pasta extraida, ZIP ou RAR.")
        digest = hashlib.sha256(data).hexdigest()
        if len(data) != expected_size or digest != entry["sha256"]:
            raise ValueError(f"SHA256/tamanho diferente do mod enviado: {expected}. Nada foi copiado deste resource.")
        if data[:4] != b"RSC7":
            raise ValueError(f"Asset GTA V Legacy RSC7 invalido: {expected}")
        target = resource / destination
        if not target.resolve().is_relative_to(resource.resolve()):
            raise ValueError(f"Destino inseguro: {target}")
        prepared.append((target, data, digest))
    # Validar todo o pacote antes de tocar nos arquivos existentes.
    for target, data, digest in prepared:
        if target.is_file() and hashlib.sha256(target.read_bytes()).hexdigest() == digest:
            print(f"OK, ja importado: {resource_name}/{target.name}")
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as handle:
            temporary = Path(handle.name)
            handle.write(data)
        try:
            temporary.replace(target)
        finally:
            temporary.unlink(missing_ok=True)
        print(f"Importado: {resource_name}/{target.name}")
    print(f"{resource_name}: {len(prepared)} assets verificados. Nenhum script do mod foi copiado ou executado.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trailblazer", type=Path, help="RAR original ou pasta extraida da Trailblazer PRF")
    parser.add_argument("--uniforms", type=Path, help="ZIP original ou pasta extraida do pack PRF v2 by wlukaas")
    args = parser.parse_args()
    if not args.trailblazer and not args.uniforms:
        parser.error("Informe --trailblazer e/ou --uniforms.")
    try:
        if args.trailblazer:
            import_resource(args.trailblazer, "prf_trailblazer")
        if args.uniforms:
            import_resource(args.uniforms, "prf_uniformes_wlukaas")
    except (OSError, ValueError, KeyError, zipfile.BadZipFile) as error:
        print(f"ERRO: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
