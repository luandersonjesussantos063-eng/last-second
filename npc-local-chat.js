// Diálogos livres opcionais com modelo nativo do navegador (Prompt API).
// Sem chave, sem provedor remoto e sem enviar conversa por uma API do jogo.
// A simulação e a fala contextual continuam disponíveis sem suporte a LanguageModel.
import { npcSummary } from "./npc-intelligence.js?v=2.22.0";
import { visitorStory } from "./reception-sim.js?v=2.22.0";
const dist=(a,b)=>Math.hypot(a.x-b.x,a.z-b.z);
export function npcCandidates(s) {
  const who=s.mode==="drive"?s.car:s.player, list=[];
  for(const a of s.command.agents) {
    if(!a.visible || a.id>=21&&s.escort.backup.stage!=="onScene")continue;
    list.push({key:"police:"+a.id,kind:"police",name:a.name,role:a.role,npc:a,
      channel:dist(who,a)<14?"presencial":"rádio"});
  }
  if(s.mode==="foot") {
    for(const v of s.reception.visitors) {
      if(["away","arriving","drivingOut"].includes(v.state)||dist(who,v)>11)continue;
      const profile=visitorStory(v.id);
      list.push({key:"civilian:"+v.id,kind:"civilian",name:profile.name,
        role:"Cidadão · "+profile.type,npc:v,channel:"presencial"});
    }
    for(const t of s.traffic) {
      if(t.speed>2.5 || dist(who,t)>11)continue;
      list.push({key:"driver:"+t.id,kind:"driver",name:"Condutor SIM-"+(2100+t.id),
        role:"Motorista fictício",npc:t,channel:"presencial"});
    }
    if(s.driver.visible && dist(who,s.driver)<9) {
      const t=s.traffic[s.mission.targetId];
      list.push({key:"inspection-driver:"+t.id,kind:"driver",
        name:"Condutor "+t.plate,role:"Condutor em fiscalização",npc:t,channel:"presencial"});
    }
  }
  return list;
}
const normalized=s=>String(s).toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g,"");
export function contextualNpcAnswer(s,person,question) {
  const q=normalized(question),mind=person.npc.mind,goal=mind?.status||"Em serviço";
  const name=person.name, memory=mind?.memories.at(-1)?.text;
  if(/blitz|fiscaliz|cone/.test(q))
    return s.checkpoint.phase==="active"
      ? "A blitz está em andamento. Estou atento à sinalização e ao movimento dos veículos."
      : "A equipe organiza a fiscalização em horários de operação. Agora sigo a rotina da unidade.";
  if(/socorro|reforc|ajuda|ocorrencia|copom/.test(q))
    return s.copom.stage==="dispatched"||s.copom.stage==="on_scene"
      ? "Há um chamado COPOM fictício em atendimento. A equipe acompanha a ocorrência pelo rádio."
      : "Se houver uma ocorrência, a central pode encaminhar apoio. Por enquanto mantenho meu setor sob observação.";
  if(/sirene|viatura|persegu|evasa/.test(q))
    return s.life.evasion.stage==="pursuit"
      ? "A motopatrulha está em uma ocorrência. A prioridade é manter distância e não interferir na operação."
      : "Ouvi o rádio da unidade. Vou seguir as orientações e manter a segurança.";
  if(/nome|quem e|quem voce|apresent/.test(q))return "Sou "+name+". "+goal+".";
  if(/obrigad|valeu|beleza/.test(q))return "Por nada. Boa viagem e mantenha atenção à rodovia.";
  if(person.kind==="driver")return "Estou acompanhando o trânsito. "+(memory?memory+". ":"")+"Vou manter distância e seguir com cuidado.";
  if(person.kind==="civilian")return "Estou aqui buscando atendimento. "+(memory||"Aguardarei a orientação da equipe.")+".";
  if(/como|tudo bem|situac|status|trabalh/.test(q))return "Tudo certo por aqui. "+goal+"."+(memory?" Última informação: "+memory+".":"");
  const templates=[
    "Entendido. Vou manter atenção ao setor e avisar no rádio se houver mudança.",
    "Boa pergunta. Neste turno estou "+goal.toLowerCase()+".",
    "Vou seguir o procedimento da unidade. "+(memory||"Por aqui o serviço está tranquilo")+".",
  ];
  return templates[(person.npc.id+question.length)%templates.length];
}
export function createNpcChatUI({getSim,release}) {
  const $=id=>document.getElementById(id),dialog=$("npcChatDialog"),
    targets=$("npcChatTarget"),answer=$("npcChatAnswer"),status=$("npcChatModelStatus");
  let model=null,opening=false,busy=false,lastCandidates=[],history=new Map();
  function updateCandidates() {
    const s=getSim(), previous=targets.value;
    lastCandidates=npcCandidates(s);
    targets.replaceChildren(...lastCandidates.map(p=>{
      const option=document.createElement("option");option.value=p.key;
      option.textContent=p.name+" · "+p.role+(p.channel==="rádio"?" [rádio]":"");
      return option;
    }));
    if(lastCandidates.some(p=>p.key===previous))targets.value=previous;
    $("npcChatSend").disabled=busy||!lastCandidates.length;
  }
  function close(){dialog.close();release();}
  function open() {
    const s=getSim();
    if(s.paused||s.inspection||!s.mode)return;
    release();updateCandidates();
    if(!dialog.open)dialog.showModal();
    status.textContent=model?"Modelo local ativado. Conversas processadas neste dispositivo.":"IA local opcional. Sem suporte, respostas contextuais gratuitas.";
    answer.textContent="Escolha um NPC e pergunte sobre seu serviço, a situação do posto ou a rodovia.";
    const native=globalThis.LanguageModel;
    $("npcChatLocalEnable").disabled=!!model||opening||!native;
    if(!native)status.textContent="Este navegador não oferece o modelo generativo local. As memórias e decisões dos NPCs continuam funcionando.";
  }
  $("npcTalkBtn").onclick=open;
  $("npcChatClose").onclick=close;
  dialog.addEventListener("cancel",e=>{e.preventDefault();close()});
  $("npcChatLocalEnable").onclick=()=>{
    const api=globalThis.LanguageModel;
    if(!api||opening||model)return;
    opening=true;
    $("npcChatLocalEnable").disabled=true;
    status.textContent="Preparando o modelo de IA no seu dispositivo. Pode ser necessário baixar arquivos...";
    // create() é chamado diretamente pelo gesto do usuário para satisfazer a política do navegador.
    const promise=api.create({monitor(m){
      m.addEventListener("downloadprogress",ev=>{
        if(dialog.open)status.textContent="Baixando IA local: "+Math.round(ev.loaded*100)+"%";
      });
    }});
    Promise.resolve(promise).then(session=>{
      model=session;
      status.textContent="IA generativa local pronta. Sem API paga.";
    }).catch(()=>{
      status.textContent="Modelo local indisponível neste dispositivo. Os diálogos contextuais continuam ativos.";
      $("npcChatLocalEnable").disabled=false;
    }).finally(()=>{opening=false;});
  };
  $("npcChatSend").onclick=async()=>{
    if(busy)return;
    updateCandidates();
    const person=lastCandidates.find(p=>p.key===targets.value);
    const question=$("npcChatInput").value.trim().slice(0,240);
    if(!person||!question)return;
    const s=getSim();if(s.paused||s.inspection)return;
    busy=true;$("npcChatSend").disabled=true;
    const recent=(history.get(person.key)||[]).slice(-4);
    let response=contextualNpcAnswer(s,person,question);
    if(model) {
      status.textContent="NPC pensando no dispositivo...";
      try{
        const prompt=[
          "Você é um personagem fictício do jogo PRF RP, ambiente brasileiro.",
          "Responda apenas em português do Brasil, naturalmente, em no máximo 2 frases curtas.",
          "Não invente ações que o jogo não tenha feito, nem documentos, placas ou fatos reais.",
          "Não aja como policial real, não acesse sistemas públicos e não dê instruções de dano.",
          "Personagem: "+person.name+". Função: "+person.role+".",
          "Personalidade e contexto: "+npcSummary(person.npc)+".",
          "Ocorrências percebidas: "+(person.npc.mind?.observations.join("; ")||"rotina tranquila")+".",
          "Conversa recente: "+recent.join(" | ")+".",
          "Jogador: "+question+"\nPersonagem:",
        ].join("\n");
        const text=await model.prompt(prompt);
        if(typeof text==="string"&&text.trim())response=text.trim().slice(0,400);
        status.textContent="Resposta gerada localmente. Sem cobrança por mensagem.";
      }catch{
        status.textContent="Modelo indisponível agora. Exibindo resposta contextual local.";
      }
    }
    answer.textContent=person.name+": "+response;
    history.set(person.key,[...recent,"Jogador: "+question,person.name+": "+response].slice(-4));
    $("npcChatInput").value="";
    busy=false;
    updateCandidates();
  };
  targets.onchange=()=>{
    const p=lastCandidates.find(x=>x.key===targets.value);
    if(p) answer.textContent=p.name+" · "+npcSummary(p.npc);
  };
  return {open,close,get isOpen(){return dialog.open;}};
}
