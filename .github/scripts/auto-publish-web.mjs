import { readFileSync } from 'node:fs';

const repo = process.env.GITHUB_REPOSITORY;
const token = process.env.GITHUB_TOKEN;
const eventName = process.env.GITHUB_EVENT_NAME;
const eventPath = process.env.GITHUB_EVENT_PATH;
const isDryRun = process.env.AUTOPUBLISH_DRY_RUN === 'true';

if (!repo || !token || !eventPath) {
  throw new Error('A publicação automática exige o token do GitHub Actions e o evento original.');
}

const event = JSON.parse(readFileSync(eventPath, 'utf8'));
const workflowRun = event.workflow_run;
const eventHead = workflowRun?.head_sha ?? null;
const prefix = '/repos/' + repo;
const allowedAgentBranch = /^ia-0[1-4]\//;
const webMarker = 'AUTO-PUBLICAR-WEB: SIM';
const docsMarker = 'AUTO-PUBLICAR-DOCS: SIM';

async function api(method, endpoint, body) {
  const response = await fetch('https://api.github.com' + endpoint, {
    method,
    headers: {
      Authorization: 'Bearer ' + token,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'PRF-RP-auto-publisher',
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  if (!response.ok) {
    const detail = (await response.text()).slice(0, 400);
    throw new Error(method + ' ' + endpoint + ' -> HTTP ' + response.status + ': ' + detail);
  }
  if (response.status === 204) return null;
  return response.json();
}

async function fileAt(path, ref) {
  const data = await api('GET', prefix + '/contents/' + path + '?ref=' + encodeURIComponent(ref));
  if (data.encoding !== 'base64' || typeof data.content !== 'string') {
    throw new Error('Arquivo não é texto versionado: ' + path);
  }
  return Buffer.from(data.content.replace(/\s/g, ''), 'base64').toString('utf8');
}

const semver = version => /^\d+\.\d+\.\d+$/.test(version)
  ? version.split('.').map(Number) : null;
function newer(current, next) {
  const a = semver(current), b = semver(next);
  if (!a || !b) return false;
  for (let i = 0; i < 3; i++) {
    if (b[i] > a[i]) return true;
    if (b[i] < a[i]) return false;
  }
  return false;
}

async function ciApproved(pr) {
  if (eventName === 'workflow_run') {
    return workflowRun?.conclusion === 'success' &&
      workflowRun?.event === 'pull_request' &&
      eventHead === pr.head.sha;
  }
  const data = await api('GET', prefix + '/actions/runs?head_sha=' + pr.head.sha + '&per_page=50');
  return data.workflow_runs?.some(run => run.head_sha === pr.head.sha &&
    run.name === 'Verificar e publicar PRF' &&
    run.event === 'pull_request' && run.conclusion === 'success');
}

function allowedPath(path) {
  return /^[\w.-]+\.js$/.test(path) ||
    path === 'index.html' || path === 'README.md' ||
    path === 'package.json' || path === 'package-lock.json' ||
    /^tests\/[\w.-]+\.test\.mjs$/.test(path) ||
    /^docs\/rp\/[\w.-]+\.md$/.test(path);
}

async function checkWebRelease(pr, changes) {
  const names = new Set(changes.map(x => x.filename));
  if (!['package.json', 'package-lock.json', 'index.html'].every(x => names.has(x))) {
    console.log('PR #' + pr.number + ': falta o incremento de versão no pacote e no HTML.');
    return false;
  }
  const basePkg = JSON.parse(await fileAt('package.json', 'main'));
  const nextPkg = JSON.parse(await fileAt('package.json', pr.head.sha));
  const nextLock = JSON.parse(await fileAt('package-lock.json', pr.head.sha));
  const baseLock = JSON.parse(await fileAt('package-lock.json', 'main'));
  const version = nextPkg.version;
  if (!newer(basePkg.version, version)) {
    console.log('PR #' + pr.number + ': versão precisa ser maior que ' + basePkg.version);
    return false;
  }
  if (nextLock.version !== version || nextLock.packages?.['']?.version !== version) {
    console.log('PR #' + pr.number + ': package-lock.json não corresponde à versão ' + version);
    return false;
  }
  // Publicação automática não permite alterar scripts, dependências ou lockfile
  // além das duas entradas de versão. Essas mudanças exigem revisão manual.
  const stripPackageVersion = obj => ({ ...obj, version: '__RELEASE__' });
  if (JSON.stringify(stripPackageVersion(basePkg)) !== JSON.stringify(stripPackageVersion(nextPkg))) {
    console.log('PR #' + pr.number + ': mudanças em package.json exigem revisão manual.');
    return false;
  }
  const stripLockVersion = obj => ({
    ...obj,
    version: '__RELEASE__',
    packages: { ...obj.packages, '': { ...obj.packages?.[''], version: '__RELEASE__' } },
  });
  if (JSON.stringify(stripLockVersion(baseLock)) !== JSON.stringify(stripLockVersion(nextLock))) {
    console.log('PR #' + pr.number + ': mudanças em dependências exigem revisão manual.');
    return false;
  }
  const html = await fileAt('index.html', pr.head.sha);
  if (!html.includes('main.js?v=' + version) || !html.includes('VERSÃO ' + version)) {
    console.log('PR #' + pr.number + ': HTML ainda não exibe a versão ' + version);
    return false;
  }
  const tree = await api('GET', prefix + '/git/trees/' + pr.head.sha + '?recursive=1');
  if (tree.truncated) return false;
  const rootModules = tree.tree.filter(x => x.type === 'blob' && /^[\w.-]+\.js$/.test(x.path));
  for (const item of rootModules) {
    const source = await fileAt(item.path, pr.head.sha);
    const cacheVersions = [...source.matchAll(/\?v=(\d+\.\d+\.\d+)/g)].map(x => x[1]);
    if (cacheVersions.some(v => v !== version)) {
      console.log('PR #' + pr.number + ': import desatualizado em ' + item.path);
      return false;
    }
  }
  return true;
}

async function run() {
  const pulls = await api('GET', prefix + '/pulls?state=open&per_page=100');
  for (const initial of pulls) {
    const p = await api('GET', prefix + '/pulls/' + initial.number);
    if (p.state !== 'open' || p.draft || p.base.ref !== 'main' ||
        p.head.repo?.full_name !== repo || !allowedAgentBranch.test(p.head.ref)) continue;
    if (!(await ciApproved(p))) continue;
    const changes = await api('GET', prefix + '/pulls/' + p.number + '/files?per_page=100');
    if (changes.length !== p.changed_files || changes.length === 0 ||
        changes.some(x => x.status === 'removed' || !allowedPath(x.filename))) {
      console.log('PR #' + p.number + ': contém arquivos que exigem revisão manual.');
      continue;
    }
    const docsOnly = changes.every(x => /^docs\/rp\/[\w.-]+\.md$/.test(x.filename));
    const marker = docsOnly ? docsMarker : webMarker;
    if (!String(p.body || '').includes(marker)) {
      console.log('PR #' + p.number + ': sem autorização de publicação automática.');
      continue;
    }
    if (!docsOnly && !(await checkWebRelease(p, changes))) continue;
    if (p.mergeable !== true || !['clean', 'unstable'].includes(p.mergeable_state)) {
      console.log('PR #' + p.number + ': aguardando resolução de conflito ou proteção de branch.');
      continue;
    }
    if (isDryRun) {
      console.log('SIMULAÇÃO: PR #' + p.number + ' está apto à publicação.');
      continue;
    }
    console.log('Integrando PR #' + p.number + ', SHA ' + p.head.sha);
    const merge = await api('PUT', prefix + '/pulls/' + p.number + '/merge', {
      sha: p.head.sha,
      merge_method: 'squash',
      commit_title: 'PRF: integrar entrega da IA ' + p.number,
    });
    if (!merge.merged) throw new Error('GitHub não confirmou merge do PR #' + p.number);
    // Push realizado com GITHUB_TOKEN não dispara novos workflows de push.
    // workflow_dispatch é exceção e inicia o deploy normal da branch main.
    await api('POST', prefix + '/actions/workflows/game-checks.yml/dispatches', { ref: 'main' });
    console.log('PR #' + p.number + ' integrado. Publicação do Pages solicitada para a main.');
    // Uma entrega por execução: outras PRs podem precisar atualizar a versão.
    return;
  }
  console.log('Nenhum PR elegível para publicação automática neste ciclo.');
}

await run();
