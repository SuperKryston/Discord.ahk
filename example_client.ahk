/*
This example require privileged Gateway Intents of 
Presence, Server Members, and Message Content. If
you only need a few of these intents, you can
calculate a value from this url:
https://discord-intents-calculator.vercel.app/

Any intents you dont have for your bot but specified
will crash the connection, i dunno why but its a
warning
*/


#Include <Discord>
#Include <JSON>
FileRead, token, token.txt
token_type = bot

If (token_type = "user")
  client := new discord(token, "user")
Else
  client := new discord(token, "bot")
client.intents := 3276799 ; All intents

client.SetOnData("MESSAGE_CREATE", "Message")
Message(Data, Intent) {
  global client
  If (Data.Content = "!ping")
    client.SendMessage("pong", data.channel_id)
  Else If (Data.Content = "!type_here")
    client.SendTyping(data.channel_id)
  Else If (Data.Content = "!online")
    client.SetPresence("online")
  Else If (Data.Content = "!dnd")
    client.SetPresence("dnd")
}
