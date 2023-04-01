local HttpService = game:GetService('HttpService')
local integrity = HttpService:GenerateGUID()

shared.WebSocket = shared.WebSocket or {
    socket = nil,
    integrity = nil,
    debug = false
}

shared.WebSocket.integrity = integrity
shared.WebSocket.debug = true

local function send_message(type, name, message)
    if (shared.WebSocket.integrity == integrity and shared.WebSocket.socket) then
        shared.WebSocket.socket:Send(HttpService:JSONEncode({
            type = type,
            name = name,
            message = message
        }))
    end
end

local function pcall_check(...)
    local success, data = pcall(...)

    if (not success) then
        send_message('error', nil, tostring(data))

        return false, data
    end

    return true, data
end

local function connect_to_ws()
    local old_socket = shared.WebSocket.socket
    pcall(old_socket and old_socket.Close or function() end, old_socket)

    local socket = WebSocket.connect('ws://localhost:56132')

    if (shared.WebSocket.integrity ~= integrity) then
        return socket:Close()
    end
    
    shared.WebSocket.socket = socket
	
	socket.OnMessage:Connect(function(script)
        local success, call_function = pcall_check(loadstring, script)

        if (success) then
            pcall_check(call_function)
        end
	end)

	socket.OnClose:Wait()
    shared.WebSocket.socket = nil
end

do
    local w = task.wait
    task.spawn(function()
        while (w() and shared.WebSocket.integrity == integrity) do
            pcall_check(connect_to_ws)
        end
    end)

    task.spawn(function()
        while (w(1) and shared.WebSocket.integrity == integrity) do
            send_message('debug_enabled', nil, tostring(shared.WebSocket.debug == true))
        end
    end)
end
