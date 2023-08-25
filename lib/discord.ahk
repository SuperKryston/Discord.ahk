class Discord {


  /*
  Intents can be set using "this.intents" as soon as client is created
  See https://discord-intents-calculator.vercel.app/
  */

  static BaseURL := "https://discord.com/api"
  ;static dump := true
  ;static dump2 := true
  static IsLoaded := false
  guilds := []
  channels := []
  static users
  static status := "online"
  static RateLimited := false
  static RateLimitCooldown := 0
  messages := {}


  SetPresence(status, afk:="", activities:="") {
    obj := {}
    obj.op := this.NoQuote(3)
    obj.d := {}

    If (status = "online") {
      obj.d.status := status
      this.status := status
    }
    Else If (status = "idle") {
      obj.d.status := status
      this.status := status
    }
    Else If (status = "dnd") {
      obj.d.status := status
      this.status := status
    }
    Else If (status = "invisible") {
      obj.d.status := status
      this.status := status
    }
    Else {
      obj.d.status := "unknown"
      this.status := "unknown"
    }
    
    obj.d.since := this.NoQuote(0)
    If (activities) && (activities != "")
      obj.d.activities := activities
    Else 
      obj.d.activities := []
    If (afk = 1 || afk = "true")
      obj.d.afk := this.NoQuote("true")
    Else
      obj.d.afk := this.NoQuote("false")
    this.__Send_Websocket(obj)
  }


  SendTyping(channel) {
    this.CallApi("POST", "/v9/channels/" . channel . "/typing")
  }

  SendMessage(message, channel) {
    data = {"content":"hi"}
    data := {}
    data.content := message
    ;data.username := "test"
    this.SendContent(data, channel)
  }


  SendContent(data, channel) {
    response := this.CallApi("POST", "/v9/channels/" . channel . "/messages", data)
    this.messages[response.id] := response
    ;Msgbox % Json.Dump(response)
  }


  GetChannelMessages(channel_id, limit:=0, before_message_id:=0) {
    messages := []

    ;Check if channel messages exists
    message_stored_count := 0
    enum := this.messages._NewEnum()
    While enum[obj, val] {
      If (val.channel_id = channel_id)
        message_stored_count := message_stored_count + 1
    }
    If (message_stored_count = 0 && limit = 0)
      limit := 50
    ;End check if channel messages exists


    If (limit !=0) {
      If (before_message_id != 0) {
        data := this.CallApi("GET", "/v9/channels/" . channel_id . "/messages?before=" . before_message_id . "&limit=" . limit)
      }
      Else {
        data := this.CallApi("GET", "/v9/channels/" . channel_id . "/messages?limit=" . limit)
      }
    }
    If (data) {
      Loop % data.Length() {
        cmessage:= data[A_Index]
        this.messages[cmessage.id] := cmessage
      }
    }


    enum := this.messages._NewEnum()
    While enum[obj, val] {
      If (val.channel_id = channel_id)
        messages.push(val)
    }
    return messages

  }

  GetCachedChannelMessages(channel_id) {

  }

  SearchPrivateChannelForId(channel_id) {
    Loop % this.private_channels.Length() {
      If (this.private_channels[A_Index].id = channel_id)
        return this.private_channels[A_Index].id
    }
    return 0
  }



  GetChannels(guild_id) {
    Loop % this.guilds.Length() {
      If (this.guilds[A_Index].id = guild_id)
        return this.guilds[A_Index].channels
    }
  }

  GetChannelData(channel_id) {
    Guild_ID := this.GetGuildByChannel(Channel_id)
    If Guild_ID {
      Guild := this.GetGuild(Guild_ID)
      enum := Guild.channels._NewEnum()
      While enum[k, v] {
        If (v.id = channel_id) {
          return v
        }
      }
    }



    Private_Channel_ID := this.SearchPrivateChannelForId(channel_id)
    If Private_Channel_ID {
      enum := this.private_channels._NewEnum()
      While enum[k, v] {
        If (v.id = channel_id) {
          return v
        }
      }
    }

  }

  GetGuildByChannel(channel_id) {
    Loop % this.guilds.Length() {
      c_guild_id := this.guilds[A_Index].id
      c_guild_channels := this.guilds[A_Index].channels
      enum := c_guild_channels._NewEnum()
      While enum[k, v] {
        ;Msgbox % Json.Dump(v,,2)
        If v.id = channel_id {
          return c_guild_id
        }
      }
    }
    return 0
  }

  GetGuild(guild_id) {
    Loop % this.guilds.Length() {
      If (this.guilds[A_Index].id = guild_id)
        return this.guilds[A_Index]
    }
  }

































  __New(token, user:="bot") {
    this._SendHeartbeat := this.__SendHeartbeat.Bind(this)


    If (user = "true" || user = true || user = 1 || user = "check" || user = "user")
      this.IsBot := false
    Else
      this.IsBot := true

    this.Token := token
    If (this.IsBot = false) {
      gateway := this.CallApi("GET", "/gateway")
      this.intents := 3276799
    }
    Else {
      gateway := this.CallApi("GET", "/gateway/bot")
      this.intents := [ "GUILDS", "GUILD_MESSAGES" ]
      this.shards := gateway.shards
      this.session_start_limit := gateway.session_start_limit
    }
    ;Msgbox % Json.Dump(gateway)
    ;Msgbox %gateway_url%
    ;gateway_url := this.__JSON_READ(gateway_url)
    gateway_url := gateway.url
    ;gateway_url := "wss://gateway.discord.gg"
    ;msgbox % WS_URL
    this.__gateway_url := gateway_url . "/?encoding=json&v=9"
    ;Msgbox % this.__gateway_url
    this.__Initialize__Websocket()
    this.status := "online"

  }
  __Initialize__Websocket() {
    static
    WS_URL := this.__gateway_url
    ;Websocket Method made by geekdude

    If (this.hWnd) {
      this.__Disconnect()
    }

    Gui, +hWndhOld
    Gui, New, +hWndhWnd
    this.hWnd := hWnd
    Gui, %hOld%: Default
    Gui, %hWnd%:Add, ActiveX, vWB, Shell.Explorer


    ; Write an appropriate document
    WB.Navigate("about:<!DOCTYPE html><meta http-equiv='X-UA-Compatible'"
    . "content='IE=edge'><body></body>")

    while (WB.ReadyState < 4)
      sleep 50
    this.document := WB.document

    ; Add our handlers to the JavaScript namespace
    this.document.parentWindow.ahk_savews := this._SaveWS.Bind(this)
    this.document.parentWindow.ahk_event := this.__Event.Bind(this)
    this.document.parentWindow.ahk_ws_url := WS_URL

    ; Add some JavaScript to the page to open a socket
    Script := this.document.createElement("script")
    Script.text := "ws = new WebSocket(ahk_ws_url);`n"
    . "ws.onopen = function(event){ ahk_event('Open', event); };`n"
    . "ws.onclose = function(event){ ahk_event('Close', event); };`n"
    . "ws.onerror = function(event){ ahk_event('Error', event); };`n"
    . "ws.onmessage = function(event){ ahk_event('Message', event); };"
    this.document.body.appendChild(Script)

    RateLimitCooldownChecker := this.__RateLimitCooldownChecker.Bind(this)
    SetTimer, %RateLimitCooldownChecker%, 1
  }


  __MsXml2Request(url, method:="GET", data:="") {
    req := ComObjCreate("Msxml2.XMLHTTP")
    req.open(method, this.BaseURL . url, True)
    req.SetRequestHeader("User-Agent", "Discord.ahk")

    If (this.IsBot = true) {
      req.SetRequestHeader("Authorization", "Bot " this.Token)
    }
    Else
      req.SetRequestHeader("Authorization", this.Token)
    req.SetRequestHeader("Content-Type", "application/json")
    req.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
    req.Send(this.Data_Dump(data))
    while (req.readyState != 4)
      sleep 1
    response := this.__JSON_READ(req.responseText)
    If (this.dump)
      FileAppend, %response%, dump.txt
    return req.responseText
  }


  __WinHttpRequest(url, method:="GET", data:="") {
    whr := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
    whr.Open(method, this.BaseURL . url, true)
    whr.SetRequestHeader("User-Agent", "Discord.ahk")

    If (this.IsBot = true) {
      whr.SetRequestHeader("Authorization", "Bot " this.Token)
    }
    Else
      whr.SetRequestHeader("Authorization", this.Token)

    whr.SetRequestHeader("Content-Type", "application/json")
    whr.Send(this.Data_Dump(Data))
    whr.WaitForResponse()
    response := this.__JSON_READ(whr.ResponseText)
    If (this.dump)
      FileAppend, %response%, dump.txt
    If (whr.status == 429) {
      Data := this.__JSON_READ(response)
      
      this.RateLimitCooldown := Data.retry_after
    }
    Else {
      return response
    }
  }

  CallApi(Method, Endpoint, Data:="") {
    return this.__WinHttpRequest(Endpoint, Method, Data)
  }

  __Event(EventName, Event)
  {
    this["__On" EventName](Event)
  }


  __OnOpen(Event)
  {
    this.IsLoaded := true
  }

  __OnMessage(Event) {
    Data := this.__JSON_READ(Event.data)
    If (Data.s)
      this.Seq := Data.s
    fn := this["__OP" Data.op]
    %fn%(this, Data)
    data :=  this.__JSON_DUMP(Data,, 2)
    ;Msgbox %data%
    If (this.dump)
      FileAppend, %data%, dump.txt
  }

  __OnError(Event) {
    Msgbox Websocket Error
  }
  __OnClose(Event) {
    ;Msgbox Websocket Closed
    this.__Disconnect()
  }

  __Send_Websocket(data) {
    datadump := this.Data_Dump(data)
    ;Msgbox %datadump%
    If (this.dump)
      FileAppend, %datadump%, dumpsentws.txt
    this.document.parentWindow.ws.send(datadump)
  }

  __Close(Code:=1000, Reason:="") {
    this.document.parentWindow.ws.close(Code, Reason)
  }

  __Disconnect()  {
    if this.hWnd
    {
      this.SetPresence("unknown", False, [])
      this.__Close()
      Gui, % this.hWnd ": Destroy"
      this.hWnd := False
      this.___setsendheartbeat(0)
    }
  }

  __Delete() {
    this.__Disconnect()
  }

  __SendHeartbeat() {
    ;if !this
    heartbeat := {}
    heartbeat.op := this.NoQuote(1)
    heartbeat.d := this.NoQuote(this.Seq)
    this.__Send_Websocket(heartbeat)
  }

  __RateLimitCooldownChecker() {
    If (this.RateLimitCooldown > 0) {
      this.RateLimited := true
      this.RateLimitCooldown := this.RateLimitCooldown - 1
    }
    Else
      this.RateLimited := false
  }
  IsRateLimited() {
    return this.RateLimited
  }

  SetOnData(DataName, Function) {
    If (!Function)
      return
    If (DataName = "OP0") {
      this.OP0 := Func(Function)
    }
    Else If (DataName = "TYPING_START") {
      this.TYPING_START := Func(Function)
    }
    Else If (DataName = "MESSAGE_CREATE") {
      this.MESSAGE_CREATE := Func(Function)
    }
    Else If (DataName = "MESSAGE_UPDATE") {
      this.MESSAGE_UPDATE := Func(Function)
    }
    Else If (DataName = "MESSAGE_DELETE") {
      this.MESSAGE_DELETE := Func(Function)
    }
    Else If (DataName = "MESSAGE_REACTION_ADD") {
      this.MESSAGE_REACTION_ADD := Func(Function)
    }
    Else If (DataName = "MESSAGE_REACTION_REMOVE") {
      this.MESSAGE_REACTION_REMOVE := Func(Function)
    }
    Else If (DataName = "MESSAGE_REACTION_REMOVE_ALL") {
      this.MESSAGE_REACTION_REMOVE_ALL := Func(Function)
    }
    Else If (DataName = "MESSAGE_REACTION_REMOVE_EMOJI") {
      this.MESSAGE_REACTION_REMOVE_EMOJI := Func(Function)
    }
    Else If (DataName = "GUILD_CREATE") {
      this.GUILD_CREATE := Func(Function)
    }
  }

  __OP0(Data) {
    If  (Data.s)
      this.Seq := data.s
    fn := this["__OP0_" Data.t]
    %fn%(this, Data.d)
    If IsObject(this.OP0) 
      this.OP0.Call(Data.d, Data.t)

    If (this.dump2) {
      t := Data.t
      d := Data.d
      IniWrite, %A_Space%, discord.dump.ini, %t%, Data
    }

    ;Msgbox % "__OP0_" Data.t
    ;Msgbox % JSON.Dump(Data,,2)
  }

  __OP0_TYPING_START(data) {
    channel_id := data.channel_id
    user_id := data.user_id
    timestamp := data.timestamp
    If (this.TYPING_START) {
      this.TYPING_START.Call(data, "TYPING_START")
    }
    ;Msgbox % Json.Dump(data,,2)
  }

  __OP0_MESSAGE_CREATE(data) {
    ;Msgbox % Json.Dump(data,,2)
    this.messages[data.id] := data
    If (this.MESSAGE_CREATE) {
      this.MESSAGE_CREATE.Call(data, "MESSAGE_CREATE")
    }
  }

  __OP0_MESSAGE_UPDATE(data) {
    this.messages[data.id] := data
    If (this.MESSAGE_UPDATE) {
      this.MESSAGE_UPDATE.Call(data, "MESSAGE_UPDATE")
    }
    ;Msgbox % Json.Dump(data,,2)
  }

  __OP0_MESSAGE_DELETE(data) {
    If (this.MESSAGE_DELETE) {
      this.MESSAGE_DELETE.Call(data, "MESSAGE_DELETE")
    }
    this.messages.Delete(data.id)
    ;Msgbox % Json.Dump(data,,2)
  }
  
  __OP0_MESSAGE_REACTION_ADD(data) {
    If (this.MESSAGE_REACTION_ADD) {
      this.MESSAGE_REACTION_ADD.Call(data, "MESSAGE_REACTION_ADD")
    }
    ;Msgbox % Json.Dump(data,,2)
  }
  __OP0_GUILD_CREATE(data) {
    found := false
    Loop % this.guilds.Length() {
      If (this.guilds[A_Index].id = data.id) {
        found := true
        this.guilds[A_Index] := data
      }
    }
    If (found = false)
      this.guilds.push(data)
    If (this.GUILD_CREATE) {
      this.GUILD_CREATE.Call(data, "GUILD_CREATE")
    }
  }

  __OP0_MESSAGE_REACTION_REMOVE(data) {
    If (this.MESSAGE_REACTION_REMOVE) {
      this.MESSAGE_REACTION_REMOVE.Call(data, "MESSAGE_REACTION_REMOVE")
    }
    ;Msgbox % Json.Dump(data,,2)
  }

  __OP0_MESSAGE_REACTION_REMOVE_ALL(data) {
    If (this.MESSAGE_REACTION_REMOVE_ALL) {
      this.MESSAGE_REACTION_REMOVE_ALL.Call(data, "MESSAGE_REACTION_REMOVE_ALL")
    }
    ;Msgbox % Json.Dump(data,,2)
  }

  __OP0_MESSAGE_REACTION_REMOVE_EMOJI(data) {
    If (this.MESSAGE_REACTION_REMOVE_EMOJI) {
      this.MESSAGE_REACTION_REMOVE_EMOJI.Call(data, "MESSAGE_REACTION_REMOVE_EMOJI")
    }
    ;Msgbox % Json.Dump(data,,2)
  }

  __OP0_READY_SUPPLEMENTAL(data) {
    ;Msgbox % Json.Dump(data,, 2)
  }


  __OP0_READY(data) {
    this.user := data.user
    this.users := data.users
    this.country_code := data.country_code
    this.consents := data.consents
    this.connected_accounts := data.connected_accounts
    this.experiments := data.experiments
    this.friend_suggestion_count := data.friend_suggestion_count
    this.geo_ordered_rtc_regions := data.geo_ordered_rtc_regions
    this.guild_experiments := data.guild_experiments
    this.guild_join_requests := data.guild_join_requests
    this.guilds := data.guilds
    this.merged_members := data.merged_members
    this.private_channels := data.private_channels
    this.read_state := data.read_state
    this.relationships := data.relationships
    this.__gateway_url := data.resume_gateway_url . "/?encoding=json&v=9"
    this.session_id := data.session_id
    this.session_type := data.session_type
    this.sessions := data.sessions
    this.user_guild_settings := data.user_guild_settings
    this.tutorial := data.tutorial
    this.user_settings_proto := data.user_settings_proto
    this.__Send_Websocket(this.__Send_After_Login())
  }

  ___setsendheartbeat(Interval) {
    static SendHeartbeat
    If (!SendHeartbeat) {
      SendHeartbeat := this._SendHeartbeat
;this.__SendHeartbeat.Bind(this)
    }
    SetTimer, % SendHeartbeat, Delete


    ;SendHeartbeat := this._SendHeartbeat
    ;this.SendHeartbeat()
    If (Interval > 0)
      SetTimer, % SendHeartbeat, % Interval
    ;Msgbox Heartbeat Modded
  }

  __OP10(Data) {
    Data := this.Data_Dump(Data)
    ;Msgbox % Data
    Data := this.__JSON_READ(Data)
    this.HeartbeatACK := True
    ;Interval := Data.d.heartbeat_interval
    this.___setsendheartbeat(Data.d.heartbeat_interval)

    this.__Send_Websocket(this.__Send_Login())
  }

  __OP11(Data) {
    this.HeartbeatACK := True
  }



  Data_Dump(data) {
    If IsObject(data)
      DataDump := this.__JSON_DUMP(data,, 2)
    Else 
      DataDump := data
    DataDump := StrReplace(DataDump, """_x__true__x_""", "true")
    DataDump := StrReplace(DataDump, """_x__false__x_""", "false")
    DataDump := StrReplace(DataDump, """_x_x", "")
    DataDump := StrReplace(DataDump, "x_x_""", "")
    return DataDump
  }

  NoQuote(Value) {
    Data := "_x_x" Value "x_x_"
    return Data
  }

  __Send_After_Login() {
    callback := {}
    callback.op := this.NoQuote(4)
    callback.d := {}
    callback.d.guild_id := this.NoQuote("null")
    callback.d.channel_id := this.NoQuote("null")
    callback.d.self_mute := this.NoQuote("true")
    callback.d.self_deaf := this.NoQuote("false")
    callback.d.self_video := this.NoQuote("false")
    return callback
  }

  Get_Intent_ID(intent) {
    ; https://discord-intents-calculator.vercel.app/
    If (intent = 1) || (intent = "GUILDS")
      return 1
    Else If (intent = 2) || (intent = "GUILD_MEMBERS")
      return 2
    Else If (intent = 4) || (intent = "GUILD_BANS")
      return 4
    Else If (intent = 8) || (intent = "GUILD_EMOJIS_AND_STICKERS")
      return 8
    Else If (intent = 16) || (intent = "GUILD_INTEGRATIONS")
      return 16
    Else If (intent = 32) || (intent = "GUILD_WEBHOOKS")
      return 32
    Else If (intent = 64) || (intent = "GUILD_INVITES")
      return 64
    Else If (intent = 128) || (intent = "GUILD_VOICE_STATES")
      return 128
    Else If (intent = 256) || (intent = "GUILD_PRESENCES")
      return 256
    Else If (intent = 512) || (intent = "GUILD_MESSAGES")
      return 512
    Else If (intent = 1024) || (intent = "GUILD_MESSAGE_REACTIONS")
      return 1024
    Else If (intent = 2048) || (intent = "GUILD_MESSAGE_TYPING")
      return 2048
    Else If (intent = 4096) || (intent = "DIRECT_MESSAGES")
      return 4096
    Else If (intent = 8192) || (intent = "DIRECT_MESSAGE_REACTIONS")
      return 8192
    Else If (intent = 16384) || (intent = "DIRECT_MESSAGE_TYPING")
      return 16384
    Else If (intent = 32768) || (intent = "MESSAGE_CONTENT")
      return 32768
    Else
      return 0
  }

  __Send_Login() {
    callback := {}
    callback.op := this.NoQuote(2)
    callback.d := {}
    ;callback.d.large_threshold := this.NoQuote(50)
    callback.d.token := this.Token
    ;callback.d.capabilities := this.NoQuote(1021)

    ; https://discord-intents-calculator.vercel.app/
    If (IsObject(this.intents)) {
      intent := 0
      enum := this.intents._NewEnum()
      While enum[obj, value]
        intent := intent + this.Get_Intent_ID(value)
      callback.d.intents := this.NoQuote(intent)
    }
    Else If (this.intents != "") {
      callback.d.intents := this.NoQuote(this.intents)
    }
    Else
      callback.d.intents := this.NoQuote(513)
    ;Msgbox % callback.d.intents
    ;callback.d.intents := this.NoQuote(3276799) 
    callback.d.properties := this.__Build_Properties()
    ;callback.d.presence := this.__Build_Presence()
    ;callback.d.compress := this.NoQuote("false")
    ;callback.d.client_state := this.__Build_Client_State()
    ;callback.d.version := this.NoQuote(9)
    return callback
  }

  __Build_Properties() {
    callback := {}
    callback["$os"] := "Windows"
    callback["$browser"] := "Discord.ahk"
    callback["$device"] := "Discord.ahk"
    ;callback.system_locale := "en-US"
    ;callback.browser_user_agent := "Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:105.0) Gecko/20100101 Firefox/105.0"
    ;callback.browser_version := 105.0
    ;callback.os_version := "7"
    ;callback.referrer := ""
    ;callback.referring_domain := ""
    return callback
  }


  __Build_Presence(presence:="online") {
    callback := {}
    callback.status := this.status
    callback.since := this.NoQuote(0)
    callback.activities := []
    callback.afk := this.NoQuote("false")
    return callback
  }
  __Build_Client_State() {
    callback := {}
    callback.guild_hashes := {}
    callback.highest_last_message_id := 0
    callback.read_state_version := this.NoQuote(0)
    callback.user_guild_settings_version := this.NoQuote(-1)
    callback.user_settings_version := this.NoQuote(-1)
    callback.private_channels_version := 0
  }

  __JSON_READ(data) {
    return JSON.Load(data)
  }
  __JSON_DUMP(data, replacer:="", space:="") {
    obj := JSON.Dump(data, replacer, space)
    return obj
  }
  


  class webhook {
    static BaseURL := "https://discord.com/api"
    __new(id, token:="") {
      If (token = "") {
        array := StrSplit(id, "/")
        Loop % array.Length() {
          If (array[A_Index] = "webhooks") {
            id := array[A_Index + 1]
            token := array[A_Index + 2]
          }
        }
      }
      this.id := id
      this.token := token
      this.webhook_endpoint := "/webhooks/" . this.id . "/" . this.token
      
      ;Msgbox % this.webhook_endpoint
      this.Get()
    }
    __Get_Process(details) {
      data := this.__JSON_READ(details)
      If (data.type)
        this.type := data.type
      ;If (data.id)
      ;  this.id := data.id
      If (data.name)
        this.name := data.name
      If (data.avatar)
        this.avatar := data.avatar
      If (data.channel_id)
        this.channel_id := data.channel_id
      If (data.guild_id)
        this.guild_id := data.guild_id
      If (data.application_id)
        this.application_id := data.application_id
      ;If (data.token)
      ;  this.token := data.token
    }
    Get() {
      this.webhook_endpoint := "/webhooks/" . this.id . "/" . this.token
      details := this.CallApi("GET", this.webhook_endpoint)
      this.__Get_Process(details)
    }
    Modify(name, avatar:="") {
      data := {}
      data.name := name
      If (FileExist(avatar)) {
        B64Data := this.Base64Enc_File(avatar)
        extpos := InStr(avatar, ".")
        ext := SubStr(avatar, extpos)
        If (ext = ".png") {
          B64Image = data:image/png;base64,%B64Data%
          data.avatar := B64Image
        }
        Else If (ext = ".jpeg") {
          B64Image = data:image/jpeg;base64,%B64Data%
          data.avatar := B64Image
        }
        Else If (ext = ".gif") {
          B64Image = data:image/gif;base64,%B64Data%
          data.avatar := B64Image
        }
      }
      Else If (avatar != "") {
        If (InStr(avatar,"data:image/") && InStr(avatar,"base64"))
          data.avatar := avatar
      }
      this.webhook_endpoint := "/webhooks/" . this.id . "/" . this.token
      details := this.CallApi("PATCH", this.webhook_endpoint, data)
      this.__Get_Process(details)
    }
    Delete() {
      this.webhook_endpoint := "/webhooks/" . this.id . "/" . this.token
      details := this.CallApi("DELETE", this.webhook_endpoint)
    }
    Execute(content, d_username:="", avatar_url:="", extra:="") {
      If (IsObject(extra))
        data := extra
      Else 
        data := {}
      data.content := content
      If (d_username != "")
        data.username := d_username
      If (avatar_url != "")
        data.avatar_url := avatar_url
      If (this.tts) {
        If (this.tts = 1) || (this.tts = "true")
          data.tts := this.NoQuote("true")
      }
      ;msgbox % this.__JSON_DUMP(data,,2)
      this.webhook_endpoint := "/webhooks/" . this.id . "/" . this.token
      details := this.CallApi("POST", this.webhook_endpoint, data)
      ;Msgbox % details
      return details
    }
    Post(content, username:="", avatar_url:="", extra:="") {
      return this.Execute(content, username, avatar_url, extra)
    }
    CallApi(Method, Endpoint, Data := "") {
      return this.__WinHttpRequest(Endpoint, Method, Data)
    }
    __WinHttpRequest(url, method:="GET", data:="") {
      whr := ComObjCreate("WinHTTP.WinHTTPRequest.5.1")
      whr.Open(method, this.BaseURL . url, true)
      whr.SetRequestHeader("User-Agent", "Discord.ahk")
      whr.SetRequestHeader("Content-Type", "application/json")
      whr.Send(this.Data_Dump(Data))
      whr.WaitForResponse()
      response := whr.ResponseText
      If (this.dump)
        FileAppend, %response%, dump.txt
      If (whr.status == 429) {
        Data := this.__JSON_READ(response)
        this.RateLimitCooldown := Data.retry_after
      }
      Else {
        return response
      }
    }
    __JSON_READ(data) {
      return JSON.Load(data)
    }
    __JSON_DUMP(data, replacer:="", space:="") {
      obj := JSON.Dump(data, replacer, space)
      return obj
    }
    Base64Enc_File(Filename) {
      FileGetSize, nBytes, %Filename%
      FileRead, Bin, *c %Filename%
      return_data := this.Base64Enc( Bin, nBytes, 100, 2 )
      return return_data
    }
    Base64Enc( ByRef Bin, nBytes, LineLength := 64, LeadingSpaces := 0 ) {
      ; By SKAN / 18-Aug-2017
      ; See https://www.autohotkey.com/boards/viewtopic.php?t=35964
      Local Rqd := 0, B64, B := "", N := 0 - LineLength + 1  ; CRYPT_STRING_BASE64 := 0x1
      DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin ,"UInt",nBytes, "UInt", 0x40000001, "Ptr",0,   "UIntP",Rqd )
      VarSetCapacity( B64, Rqd * ( A_Isunicode ? 2 : 1 ), 0 )
      DllCall( "Crypt32.dll\CryptBinaryToString", "Ptr",&Bin, "UInt",nBytes, "UInt", 0x40000001, "Str",B64, "UIntP",Rqd )
      If ( LineLength = 64 and ! LeadingSpaces )
        Return B64
      B64 := StrReplace( B64, "`r`n" )        
      Loop % Ceil( StrLen(B64) / LineLength )
        B .= Format("{1:" LeadingSpaces "s}","" ) . SubStr( B64, N += LineLength, LineLength ) . "`n" 
      Return RTrim( B,"`n" )    
    }
    Data_Dump(data) {
      If IsObject(data)
        DataDump := this.__JSON_DUMP(data,, 2)
      Else 
        DataDump := data
      DataDump := StrReplace(DataDump, """_x__true__x_""", "true")
      DataDump := StrReplace(DataDump, """_x__false__x_""", "false")
      DataDump := StrReplace(DataDump, """_x_x", "")
      DataDump := StrReplace(DataDump, "x_x_""", "")
      return DataDump
    }

    NoQuote(Value) {
      Data := "_x_x" Value "x_x_"
      return Data
    }
  } ;End Webhook


}
