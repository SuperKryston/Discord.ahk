#Include <JSON>
#Include <Discord>


webhook_url = https://discord.com/api/webhooks/1024952168379330561/QBojtYI1Oa_cumia1Ox8m6Ew_ppoN1hEN9vI5tsMAHYQBimbrEJdATArhISuGfqAC30s

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

Webhook.Execute("My custom message", A_ComputerName, image_icon2)
