--純開關

--switch、PH2、馬達
Version = "v100"  --13308122/13308239
num=2

--switch
Item = 0
state = 0--狀態

--以下so皆為控制繼電器，註解為繼電器各自控制之設備
so1 = 4 --gpio 2（供應灌溉暨營養液供給區水源(含馬達及繼電器)）
gpio.mode(so1, gpio.OUTPUT)
gpio.write(so1, gpio.HIGH)
so2 = 2 --gpio 4（營養液給予器控制電磁閥：控制營養液供給）
gpio.mode(so2, gpio.OUTPUT)
gpio.write(so2, gpio.HIGH)
so3 = 1 --gpio 5（灌溉區域排水電磁閥）
gpio.mode(so3, gpio.OUTPUT)
gpio.write(so3, gpio.HIGH)
so4 = 6 --gpio 12（硝化菌槽排水電磁閥&回收水抽水馬達）
gpio.mode(so4, gpio.OUTPUT)
gpio.write(so4, gpio.HIGH)


wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid="zhichen"
station_cfg.pwd="578380985688"
station_cfg.auto=true
station_cfg.save=true
wifi.sta.config(station_cfg)
wifitimer = tmr.create()
wifitimer:alarm(1000, tmr.ALARM_AUTO, function()
    if wifi.sta.status() == 5 then
        print("wifi connecting...")
        print(wifi.sta.getip())
      if not wifitimer:stop() then print("timer not stopped, not registered?") end
    end
end)

MQTTid = node.chipid()
MQTTStimer = tmr.create()
    MQTTStimer:alarm(3000, tmr.ALARM_AUTO, function()
     if wifi.sta.status() ~= 5 then
        print("wifi connecting...")
     end 
       
    m = mqtt.Client(MQTTid, 120, "user1", "password0101", 1, 1024)
    m:lwt("/lwt", "offline", 0, 0)  --遺囑
    m:on("connect", function(client) print ("connected") end)
    m:on("connfail", function(client, reason) print ("connection failed", reason) end)
    m:on("offline", function(client)  print ("offline") end)
    m:on("message", function(client, topic, mdata) 
      msg = string.format("%s",mdata)--轉string   
            
            --自動排程1~5
            if mdata ~= nil and topic == "switch" then
              if msg == "1" then
                gpio.write(so1, gpio.LOW)
                gpio.write(so2, gpio.LOW)
                gpio.write(so3, gpio.HIGH)
                gpio.write(so4, gpio.HIGH)
                client:publish("Item", "1", 1, 1, function(client) end)
                print("Item 1")
              elseif msg == "2" then
                gpio.write(so1, gpio.LOW)
                gpio.write(so2, gpio.HIGH)
                gpio.write(so3, gpio.HIGH)
                gpio.write(so4, gpio.HIGH)
                client:publish("Item", "2", 1, 1, function(client) end)
                print("Item 2")
              elseif msg == "3" then
                gpio.write(so1, gpio.LOW)
                gpio.write(so2, gpio.HIGH)
                gpio.write(so3, gpio.LOW)
                gpio.write(so4, gpio.LOW)
                client:publish("Item", "3", 1, 1, function(client) end)
                print("Item 3")
              elseif msg == "4" then
                gpio.write(so1, gpio.HIGH)
                gpio.write(so2, gpio.HIGH)
                gpio.write(so3, gpio.LOW)
                gpio.write(so4, gpio.HIGH)
                client:publish("Item", "4", 1, 1, function(client) end)
                print("Item 4")
              elseif msg == "5" then
                gpio.write(so1, gpio.HIGH)
                gpio.write(so2, gpio.HIGH)
                gpio.write(so3, gpio.LOW)
                gpio.write(so4, gpio.LOW)
                client:publish("Item", "5", 1, 1, function(client) end)
                print("Item 5")
              else
                gpio.write(so1, gpio.HIGH)
                gpio.write(so2, gpio.HIGH)
                gpio.write(so3, gpio.HIGH)
                gpio.write(so4, gpio.HIGH)
                client:publish("Item", "0", 1, 1, function(client) end)
                print("Item 6")
              end
            end
    end)
  
   m:on("overflow", function(client, topic, mdata) end)   
   m:connect("broker.emqx.io", 1883, false, function(client, reason)
      print("MQTT_connected")
      --訂閱主題為："CheckID"
      client:subscribe({["watersensor"]=0,["PH"]=0,["TDS"]=0,["dht11"]=0,["ds18b20"]=0,["switch"]=0}, function(client) MQTTStimer:stop() print("subscribe success") end) --多訂閱
      pubtimer = tmr.create()
      pubtimer:alarm(5000, tmr.ALARM_AUTO, function()
          
      end)
   end,
   function(client, reason)
      print("failed reason: " .. reason)
   end)
  end)   
