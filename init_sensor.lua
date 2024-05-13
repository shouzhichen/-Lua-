--感測器版
--PH1、watersensor1、watersensor2、
Version = "v100"  --13308122/13308239
num=2

--PH1
adcpin = 0 --A0為一類比轉數位轉換器
adcdata = 0

--watersensor1
pin4 = 6 --gpio 02（MOTO_S）
weatersensor2_state = 0 --狀態
gpio.mode(pin4, gpio.INPUT)


--watersensor2
pin5 = 7 --gpio 14（BUZZER_S）
weatersensor3_state = 0 --狀態
gpio.mode(pin5, gpio.INPUT)


--dht22
pin6 = 5 --D0
gpio.mode(pin6, gpio.INPUT)

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
            if mdata ~= nil and topic == "PH1" then
                if msg ~= "PH1 error" then
                    if msg > "9.0" then
                        print("管耕區過鹼")
                        client:publish("sensor_return", "管耕區過鹼", 1, 1, function(client) end)
                    elseif msg < "7.5" then
                        print("管耕區過酸")
                        client:publish("sensor_return", "管耕區過酸", 1, 1, function(client) end)
                    else
                        print("管耕區酸鹼值正常")
                        client:publish("sensor_return", "管耕區酸鹼值正常", 1, 1, function(client) end)
                    end
                else
                    print("PH1故障")
                    client:publish("sensor_return", "PH1故障", 1, 1, function(client) end)
                end
            end
            
            --dht22
            if mdata ~= nil and topic == "dht22" then
                if msg == "ERROR_CHECKSUM" or "ERROR_TIMEOUT" then
                    print("dht22故障")
                    client:publish("sensor_return", "dht22故障", 1, 1, function(client) end)
                elseif msg < "25" then
                    print("dht22溫度過低")
                    client:publish("sensor_return", "dht22溫度過低", 1, 1, function(client) end)
                elseif msg > "30" then
                    print("dht22溫度過高")
                    client:publish("sensor_return", "dht22溫度過高", 1, 1, function(client) end)
                else
                    print("dht22溫度正常")
                    client:publish("sensor_return", "dht22溫度正常", 1, 1, function(client) end)
                end
            end
    end)
  
   m:on("overflow", function(client, topic, mdata) end)   
   m:connect("10.10.10.4", 1883, false, function(client, reason)
      print("MQTT_connected")
      --訂閱主題為："CheckID"
      client:subscribe({["watersensor"]=0,["PH"]=0,["TDS"]=0,["dht11"]=0,["ds18b20"]=0,["switch"]=0}, function(client) MQTTStimer:stop() print("subscribe success") end) --多訂閱
      pubtimer = tmr.create()
      pubtimer:alarm(5000, tmr.ALARM_AUTO, function()
       --發佈主題為：DeviceCheck 
       --client:publish(MQTTid.."DeviceStatus", "success", 1, 1, function(client) MQTTStimer:stop() end)
        
        --watersensor1
        if gpio.read(pin4) == 1 then
          client:publish("1", "111", 1, 1, function(client) end)
          print("watersensor1 is full.")
        else
          client:publish("1", "110", 1, 1, function(client) end)
          print("watersensor1 is not full.")
        end
        
        --watersensor2
        if gpio.read(pin5) == 1 then
          client:publish("1", "121", 1, 1, function(client) end)
          print("watersensor2 is full.")
        else
          client:publish("1", "120", 1, 1, function(client) end)
          print("watersensor2 is not full.")
        end
        
        --PH_1
        if gpio.read(adcpin) ~= 0 then
          adcdata = adc.read(adcpin) --(不確定read讀出來是否為int，也不確定是否可以用adc.read直接傳mqtt)
          client:publish("4", adcdata.."", 1, 1, function(client) end)
          print("PH：", adcdata)
        else 
          client:publish("4", "999", 1, 1, function(client) end)
          print("PH error")
        end
        
        --dht22  
        status, temp2, humi, temp_dec, humi_dec = dht.read(pin6)
        if status == dht.OK then
          client:publish("2", "0"..temp2.."", 1, 1, function(client) end)
          print("DHT11 Temperature:"..temp2.."")
        end
        if status == dht.ERROR_CHECKSUM then
          client:publish("2", "2000", 1, 1, function(client) end)
          print("DHT11 error")
        end
        if status == dht.ERROR_TIMEOUT then
          client:publish("2", "2999", 1, 1, function(client) end)
          print("DHT11 timed out")
        end
      end)
   end,
   function(client, reason)
      print("failed reason: " .. reason)
   end)
  end)   
