-- Apenas palavras exatas da lista viram comandos. Nao executa texto do chat.
AddEventHandler('chatMessage',function(src,author,message)
  if type(message)~='string' or #message>32 then return end
  local word=message:match('^%s*(%S+)%s*$')
  if not word then return end
  word=word:lower():gsub('^/','')
  local action=Config.ChatCommands[word]
  if not action then return end
  CancelEvent()
  if action~='help' and action~='base' and action~='favela' then
    if not IsPlayerAceAllowed(src,'prfrp.officer') then
      TriggerClientEvent('prfrp:notify',src,'Acesso PRF negado. Configure sua permissao ACE.'); return
    end
    if action~='duty' and (not PrfHasDuty or not PrfHasDuty(src)) then
      TriggerClientEvent('prfrp:notify',src,'Digite servico no T primeiro.'); return
    end
  end
  TriggerClientEvent('prfrp:chatCommand',src,word)
end)
