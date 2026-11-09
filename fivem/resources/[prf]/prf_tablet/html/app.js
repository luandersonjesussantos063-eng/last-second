const root = document.getElementById('tablet');
const count = document.getElementById('count');
const calls = document.getElementById('calls');
const closeButton = document.getElementById('close');

function addCall(item) {
  const article = document.createElement('article');
  article.className = 'call';
  const main = document.createElement('div');
  const title = document.createElement('h3');
  title.textContent = String(item.title ?? 'Ocorrência');
  const description = document.createElement('p');
  description.textContent = [item.id, item.kind, item.route].map(v => String(v ?? '')).filter(Boolean).join(' • ');
  const status = document.createElement('strong');
  status.textContent = String(item.status ?? 'Aberto');
  main.append(title, description);
  article.append(main, status);
  calls.append(article);
}
window.addEventListener('message', ({ data }) => {
  if (data?.type === 'prf:close') {
    root.hidden = true;
    return;
  }
  if (data?.type !== 'prf:open') return;
  const items = Array.isArray(data.calls) ? data.calls.slice(0, 50) : [];
  calls.replaceChildren();
  count.textContent = String(items.length);
  if (items.length === 0) {
    const msg = document.createElement('p');
    msg.className = 'empty';
    msg.textContent = 'Nenhuma ocorrência fictícia cadastrada.';
    calls.append(msg);
  }
  items.forEach(addCall);
  root.hidden = false;
  closeButton.focus();
});
async function closeTablet() {
  try {
    await fetch('https://' + GetParentResourceName() + '/close', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify({}),
    });
  } catch (err) { console.warn('Não foi possível fechar pelo callback NUI', err); }
  root.hidden = true;
}
closeButton.addEventListener('click', closeTablet);
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && !root.hidden) { event.preventDefault(); void closeTablet(); }
});
