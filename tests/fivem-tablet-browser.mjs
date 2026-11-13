import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import { resolve, join } from 'node:path';
import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
const base=resolve('fivem/resources/[prf]/prf_core/html');
const server=createServer((req,res)=>{const name=req.url==='/'?'index.html':req.url.slice(1);if(!['index.html','style.css','app.js'].includes(name)){res.writeHead(404);res.end();return;}res.setHeader('Content-Type',name.endsWith('.js')?'text/javascript':name.endsWith('.css')?'text/css':'text/html');res.end(readFileSync(join(base,name)));});
await new Promise(done=>server.listen(0,'127.0.0.1',done));
const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
try{
 const page=await browser.newPage({viewport:{width:1440,height:1000}});
 const requests=[];
 await page.route('https://prf_core/**',async route=>{requests.push({name:route.request().url().split('/').at(-1),data:route.request().postDataJSON()});await route.fulfill({body:'{}',headers:{'Access-Control-Allow-Origin':'*'}});});
 await page.goto('http://127.0.0.1:'+server.address().port);
 assert(await page.locator('#tablet').isHidden());
 await page.evaluate(()=>window.postMessage({action:'open',tab:'documents',lines:['DOCUMENTO FICTÍCIO | João Oliveira','ANTECEDENTES | Sem passagem','<img src=x onerror="window.injected=true">'],profile:{stats:{calls:4,missions:2,arrests:1,seizures:3},items:[{label:'Fuzil (CARBINERIFLE)',count:1},{label:'Munição de fuzil',count:90}],arrests:[{number:1,name:'João Oliveira',document:'SIM-100-2031'}]}},'*'));
 await page.locator('#tablet').waitFor({state:'visible'});
 assert.equal(await page.locator('#report img').count(),0);assert(!(await page.evaluate(()=>window.injected)));
 await page.locator('[data-tab=inventory]').click();assert.match(await page.locator('#items').innerText(),/CARBINERIFLE/);
 await page.locator('[data-tab=progress]').click();await page.locator('#save').click();await page.waitForTimeout(100);
 assert(requests.some(r=>r.name==='save'));
 await page.locator('[data-tab=services]').click();await page.locator('[data-service=mechanic]').click();await page.waitForTimeout(100);
 assert(requests.some(r=>r.name==='service'&&r.data.name==='mechanic'));
 await page.keyboard.press('Escape');await page.waitForTimeout(100);assert(requests.some(r=>r.name==='close'));
 await page.locator('[data-tab=progress]').click();await page.screenshot({path:'/workspace/work/prf-070-tablet.png'});
 await page.evaluate(()=>window.postMessage({action:'close'},'*'));await page.locator('#tablet').waitFor({state:'hidden'});
 console.log('Tablet browser checks passed: document, safe text, inventory, progress, services, save and Escape.');
}finally{await browser.close();await new Promise(done=>server.close(done));}
