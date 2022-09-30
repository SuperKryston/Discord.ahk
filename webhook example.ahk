#Include <JSON>
#Include <Discord>

;Place your url here
webhook_url = 

image_icon := "http://i.imgur.com/dS56Ewu.png"
image_icon2 := "https://imgur.com/Yuviqei.png"
File := "ahkicon.png"
If ! FileExist( File )
URLDownloadToFile, %image_icon%, %File%

AhkNewName = Autohotkey Webhook

webhook := new discord.webhook(webhook_url)
;You can also do webhook := new discord.webhook(id, token)

Msgbox % "Your current webhook name is: " . webhook.name . "`nBut I will change it to: " . AhkNewName

webhook.Modify(AhkNewName, File)

Msgbox % "Your webhook name is: " . webhook.name . "`nDont believe me? Check discord"

;An example of adding extra raw data to webhook post
raw_extra := {}
embed := {}
embed.title := "Discord.ahk"
embed.description := "Checkout ""https://github.com/SuperKryston/Discord.ahk"" for help"
embed.color := Discord.NoQuote(16711680) ; Because JSON.ahk would quote this and this is required as int rather than string
raw_extra.embeds := [ embed ]


Webhook.Execute("My custom message", A_ComputerName, image_icon2, raw_extra)
