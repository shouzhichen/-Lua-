Version = "v100"  --13308122/13308239
num=2
local t = require("ds18b20")
local pin = 3 -- gpio0 = 3, gpio2 = 4
local pin2 = 2
local msg = ""
--[[local t = require("ds18b20")
local pin = 3 -- gpio0 = 3, gpio2 = 4
msg = 0
local function readout(temps)
  for addr, temp in pairs(temps) do
    msg = math.floor(temp)
    print(math.floor(temp).."度(1)\n")
  end
  return msg
end

do
  t:enable_debug()
  file.remove("ds18b20_save.lc") -- remove saved addresses
  t:read_temp(readout, pin)
end]]

wifi.setmode(wifi.STATION)
station_cfg={}
station_cfg.ssid="Cisco_IoT"
station_cfg.pwd="12345678"
station_cfg.auto=true
station_cfg.save=true
wifi.sta.config(station_cfg)
wifitimer = tmr.create()
wifitimer:alarm(1000, tmr.ALARM_AUTO, function()
    if wifi.sta.status() == 5 then
        print("wifi connecting...")
        print(wifi.sta.getip())
        if not wifitimer:stop() then 
            print("timer not stopped, not registered?") 
        end
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
    end)
    
    m:on("overflow", function(client, topic, mdata) end)   
    m:connect("10.10.10.4", 1883, false, function(client, reason)
        print("MQTT_connected")
    --訂閱主題為："CheckID"
    client:subscribe({["watersensor"]=0,["PH"]=0,["TDS"]=0,["dht11"]=0,["ds18b20"]=0,["switch"]=0}, function(client) MQTTStimer:stop() print("subscribe success") end) --多訂閱
    pubtimer = tmr.create()
    pubtimer:alarm(1000, tmr.ALARM_AUTO, function()
    --發佈主題為：DeviceCheck 
    --client:publish(MQTTid.."DeviceStatus", "success", 1, 1, function(client) MQTTStimer:stop() end)
    
    
    local function readout(temps)
      for addr, temp in pairs(temps) do
        print(math.floor(temp).."度(1)\n")
        client:publish("31", math.floor(temp).."", 1, 1, function(client) MQTTStimer:stop() end)
      end
    end
    do
      t:enable_debug()
      file.remove("ds18b20_save.lc") -- remove saved addresses
      t:read_temp(readout, pin)
    end
  end)
end,
function(client, reason)
    print("failed reason: " .. reason)
end)
end)   
