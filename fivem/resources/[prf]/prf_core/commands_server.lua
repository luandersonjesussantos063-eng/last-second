-- Apenas palavras exatas da lista viram comandos. Nao executa texto do chat.
AddEventHandler('chatMessage',function(src,author,message)
  local word,args=PrfParseChat(message)
  if not word then return end
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
  TriggerClientEvent('prfrp:chatCommand',src,word,args)
end)
