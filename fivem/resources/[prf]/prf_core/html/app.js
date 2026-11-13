const tablet=document.querySelector('#tablet');
const sections=['documents','inventory','progress','services'];
const call=(name,data={})=>fetch(`https://${typeof GetParentResourceName==='function'?GetParentResourceName():'prf_core'}/${name}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(data)}).catch(()=>{});
const row=(text,kind='row')=>{const element=document.createElement('div');element.className=kind;element.textContent=String(text);return element;};
function tab(name){if(!sections.includes(name))name='documents';for(const id of sections)document.querySelector('#'+id).hidden=id!==name;for(const button of document.querySelectorAll('[data-tab]'))button.classList.toggle('active',button.dataset.tab===name);}
function profile(value={}){
  const items=document.querySelector('#items');items.replaceChildren();
  for(const item of Array.isArray(value.items)?value.items:[]){const element=row(item.label,'row item');const count=document.createElement('strong');count.textContent='× '+item.count;element.append(count);items.append(element);}
  if(!items.childElementCount)items.append(row('Nenhuma apreensão no inventário.','empty'));
  const stats=document.querySelector('#stats');stats.replaceChildren();
  for(const [key,label] of [['calls','Ocorrências atendidas'],['missions','Rondas concluídas'],['arrests','Prisões registradas'],['seizures','Armas apreendidas']]){const element=row(label,'stat');const count=document.createElement('b');count.textContent=Number(value.stats?.[key]||0);element.prepend(count);stats.append(element);}
  const arrests=document.querySelector('#arrests');arrests.replaceChildren();
  for(const item of (Array.isArray(value.arrests)?value.arrests:[]).slice(-5).reverse())arrests.append(row(`#${item.number} — ${item.name} · ${item.document}`));
  if(!arrests.childElementCount)arrests.append(row('Nenhuma prisão registrada.','empty'));
}
window.addEventListener('message',({data})=>{
  if(!data||typeof data!=='object')return;
  if(data.action==='close')tablet.hidden=true;
  if(data.action==='open'){tablet.hidden=false;tab(data.tab);profile(data.profile);const report=document.querySelector('#report');report.replaceChildren();for(const line of Array.isArray(data.lines)?data.lines:[])report.append(row(line));if(!report.childElementCount)report.append(row('Use documento no T durante uma abordagem.','empty'));}
  if(data.action==='profile')profile(data.profile);
  if(data.action==='notice')document.querySelector('#notice').textContent=String(data.text);
});
document.querySelector('#close').onclick=()=>call('close');
document.querySelector('#save').onclick=()=>call('save');
for(const button of document.querySelectorAll('[data-tab]'))button.onclick=()=>tab(button.dataset.tab);
for(const button of document.querySelectorAll('[data-service]'))button.onclick=()=>{call('service',{name:button.dataset.service});document.querySelector('#notice').textContent='Solicitação enviada';};
document.addEventListener('keydown',event=>{if(event.key==='Escape')call('close');});
