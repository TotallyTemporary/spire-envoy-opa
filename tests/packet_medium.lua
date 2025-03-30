
init = function(args)
  file = io.open("packets/packet_data_medium.bin", "rb")
  data = file:read("*a")
  file:close()
  
  wrk.headers["Content-Type"] = "application/octet-stream"
  req = wrk.format("POST", "/", nil, data)
end

request = function()
   return req
end
