// Mente compartilhada por policiais, civis e motoristas do PRF RP.
// Percepção espacial, memória curta e escolha de objetivos com utilidade.
// Nenhuma rede/IA paga: simulação determinística, com personalidade individual.
export const NPC_MEMORY_LIMIT = 8;
export const NPC_ROLES = ["police", "civilian", "driver"];
const PERSONALITIES = ["calmo","atento","sociável","prudente","curioso","metódico","prestativo","observador"];
const mix = (kind,id) => (id*17 + (kind==="police"?13:kind==="civilian"?37:61)) >>> 0;
const distance = (a,b) => Math.hypot(a.x-b.x,a.z-b.z);
export function createNpcMind(kind,id) {
  if (!NPC_ROLES.includes(kind) || !Number.isInteger(id) || id<0)
    throw new Error("Tipo ou identidade de NPC inválidos");
  const seed=mix(kind,id);
  return {
    kind,id,personality:PERSONALITIES[seed%PERSONALITIES.length],
    cautious:0.65+(seed%5)*0.075,
    social:0.15+((seed*3)%7)*0.1,
    goal:"observar", status:"Observando o ambiente",
    observations:[],memories:[],seen:{},nextThought:0,
    thoughtCount:0, pace:1, patience:0, mood:"tranquilo",
  };
}
export function rememberNpc(mind,type,key,text,time) {
  if (!mind || mind.seen[type]===key) return false;
  mind.seen[type]=key;
  mind.memories.push({type,text:String(text).slice(0,100),time:Math.round(time)});
  if(mind.memories.length>NPC_MEMORY_LIMIT)mind.memories.shift();
  return true;
}
export function perceiveNpc(s,npc,mind) {
  const events=[],position=npc;
  const player=s.mode==="drive"?s.car:s.player;
  const separation=distance(position,player);
  if(separation<80 && s.mode==="drive" && s.car.siren && s.car.speed>0.5)
    events.push({type:"siren",key:"siren:"+Math.floor(s.time/20),
      label:"Viatura com sirene se aproximando",intensity:Math.max(0,1-separation/85)});
  if(mind.kind==="police") {
    if(s.life.evasion.stage==="pursuit")events.push({type:"evasion",key:"evasion:"+s.life.evasion.vehicleId+":"+s.life.evasion.completed,label:"Ocorrência de evasão comunicada pelo rádio",intensity:1});
    if(s.escort.backup.stage==="enroute")events.push({type:"backup",key:"backup:"+s.escort.backup.since,label:"Reforço solicitado pelo comandante",intensity:0.9});
    if(s.checkpoint.phase==="active" && Math.abs(position.z)<80)
      events.push({type:"blitz",key:"blitz:"+s.clock.day,label:"Fiscalização em andamento",intensity:0.7});
    if(s.reception.visitors.filter(v=>v.state==="queue").length>=3 &&
        (npc.id===0 || npc.id===1 || npc.id===7))
      events.push({type:"queue",key:"queue:"+Math.floor(s.time/35),label:"Pessoas aguardando na recepção",intensity:0.8});
    if(s.copom.stage==="dispatched" && (npc.id===7 || npc.id===8))
      events.push({type:"copom",key:"copom:"+s.copom.serial,label:"Novo atendimento COPOM no trecho",intensity:0.65});
  } else if(mind.kind==="civilian") {
    if(npc.state==="queue")events.push({type:"waiting",key:"ticket:"+npc.ticket,label:"Aguardando chamada para atendimento",intensity:0.5});
    if(npc.state==="player"||npc.state==="agent")
      events.push({type:"service",key:"service:"+npc.ticket,label:"Em atendimento",intensity:0.7});
  } else if(mind.kind==="driver") {
    if(s.checkpoint.phase==="active" && Math.abs(npc.z)<90)
      events.push({type:"blitz",key:"blitz:"+s.clock.day,label:"Fiscalização rodoviária à frente",intensity:0.75});
    if(npc.stopped) events.push({type:"stop",key:"stop:"+Math.floor(s.time/35),
      label:"Veículo parado por uma ocorrência",intensity:1});
    const others=s.traffic.filter(t=>t!==npc &&
      Math.abs(t.x-npc.x)<2.3 && (t.z-npc.z)*npc.direction>0 &&
      (t.z-npc.z)*npc.direction<42).sort((a,b)=>
      (a.z-npc.z)*npc.direction-(b.z-npc.z)*npc.direction);
    if(others.length)events.push({type:"lead",key:"lead:"+others[0].id,label:"Trânsito mais lento à frente",intensity:0.5});
  }
  return events;
}
export function chooseNpcGoal(s,npc,mind,events) {
  // Uma decisão por prioridades, com metas individualizadas.
  const priorities = new Map([["observar",1]]);
  const put=(goal,score)=>priorities.set(goal,Math.max(priorities.get(goal)||0,score));
  const has=type=>events.some(e=>e.type===type);
  const recent=type=>mind.memories.some(e=>e.type===type && s.time-e.time<35);
  if(mind.kind==="police") {
    put("ronda",1.2+mind.cautious);
    put("comunicar",0.8+mind.social);
    if(has("evasion"))put("apoiar_ocorrencia",10);
    if(has("backup"))put("acompanhar_reforco",8);
    if(has("queue"))put("atender",7);
    if(has("copom"))put("acompanhar_copom",6.5);
    if(has("blitz"))put("fiscalizar",6);
    if(recent("evasion")&&!has("evasion"))put("registrar_ocorrencia",4);
    // A missão/ordem existente é autoritativa; o cérebro nunca a cancela.
    if(npc.teamwork && npc.task==="routine")put("cooperar",95);
    if(npc.task!=="routine")put("cumprir_ordem",100);
    if([18,19,20].includes(npc.id)&&s.escort.stage!=="idle")put("acompanhar_comandante",120);
  } else if(mind.kind==="civilian") {
    put("seguir_rotina",1);
    if(["arriving","enter"].includes(npc.state))put("ir_recepcao",7);
    if(npc.state==="queue")put("aguardar_atendimento",9);
    if(["player","agent","called","agentWalk"].includes(npc.state))put("prestar_informacoes",11);
    if(["exit","drivingOut"].includes(npc.state))put("retornar_viagem",10);
    if(has("siren"))put("observar_emergencia",4);
  } else {
    put("seguir_viagem",2+mind.cautious);
    if(has("lead"))put("manter_distancia",6);
    if(has("siren"))put("reduzir_por_sirene",9);
    if(has("blitz"))put("reduzir_para_fiscalizacao",7);
    if(has("stop"))put("aguardar_liberacao",12);
  }
  const selected=[...priorities].sort((a,b)=>b[1]-a[1])[0][0];
  return selected;
}
const labels={
  observar:"Observando o movimento",ronda:"Vigilância preventiva",comunicar:"Monitorando rádio",cooperar:"Prestando apoio a outro setor",
  apoiar_ocorrencia:"Acompanhando evasão comunicada",acompanhar_reforco:"Aguardando reforço",
  atender:"Atendimento à recepção",acompanhar_copom:"Monitorando chamado COPOM",
  fiscalizar:"Fiscalização ativa",registrar_ocorrencia:"Registrando atendimento",
  cumprir_ordem:"Cumprindo ordem do comandante",acompanhar_comandante:"Acompanhando comandante",
  seguir_rotina:"Na rotina do cidadão",ir_recepcao:"Buscando recepção",
  aguardar_atendimento:"Esperando ser chamado",prestar_informacoes:"Prestando informações",
  retornar_viagem:"Retornando para o veículo",observar_emergencia:"Observando viatura",
  seguir_viagem:"Conduzindo com atenção",manter_distancia:"Mantendo distância segura",
  reduzir_por_sirene:"Reduzindo ao ouvir sirene",
  reduzir_para_fiscalizacao:"Reduzindo para fiscalização",
  aguardar_liberacao:"Aguardando liberação",
};
export function updateNpcMinds(s) {
  if(s.time < (s.nextNpcThoughtAt??0))return false;
  s.nextNpcThoughtAt=s.time+1.2;
  const groups=[
    ...s.command.agents.map(a=>["police",a]),
    ...s.reception.visitors.map(v=>["civilian",v]),
    ...s.traffic.map(t=>["driver",t]),
  ];
  for(const [kind,npc] of groups) {
    npc.mind ??= createNpcMind(kind,npc.id);
    const mind=npc.mind;
    if(s.time<mind.nextThought)continue;
    const observations=perceiveNpc(s,npc,mind);
    const active=new Set(observations.map(e=>e.type));
    for(const e of observations)rememberNpc(mind,e.type,e.key,e.label,s.time);
    for(const type of Object.keys(mind.seen))if(!active.has(type))delete mind.seen[type];
    mind.observations=observations.map(e=>e.label).slice(0,4);
    mind.goal=chooseNpcGoal(s,npc,mind,observations);
    mind.status=mind.goal==="cooperar" ? npc.teamwork.working : labels[mind.goal]??"Observando";
    mind.mood=observations.some(e=>e.intensity>=0.9)?"alerta":mind.goal==="aguardar_atendimento"?"paciente":"tranquilo";
    mind.thoughtCount++;
    mind.nextThought=s.time+1.2+(npc.id%5)*0.21;
    // O ajuste na velocidade é limitado e nunca sobrepõe colisões, missões ou blitz.
    if(kind==="driver") {
      const limited=hasSpeedLimit(mind.goal);
      const max=mind.goal==="reduzir_por_sirene"?0.62:0.7;
      mind.pace=limited?max*(0.91+Math.min(0.09,mind.cautious*0.08)):1;
    }
  }
  return true;
}
function hasSpeedLimit(goal) {
  return goal==="reduzir_por_sirene" || goal==="reduzir_para_fiscalizacao";
}
export function npcSummary(npc) {
  if(!npc.mind)return "Observando o ambiente";
  const m=npc.mind, recent=m.memories.at(-1);
  return m.personality+" · "+m.status+(recent?" · "+recent.text:"");
}
