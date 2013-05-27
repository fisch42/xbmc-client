
Emitter = require 'emitter'

buttons =
	Player: ['PlayPause', 'Stop'],
	Input: ['Up', 'Down', 'Left', 'Right', 'Select', 'Back', 'Home']

class XbmcClient extends Emitter
	
	constructor: (@ip, @port) ->
		@requests = {}
		@id = 0
		@player = null
		@connect @ip, @port
		@listen()
	
	connect: (ip, port) ->
		@ws = new WebSocket 'ws://'+ip+':'+port+'/jsonrpc'
		@ws.addEventListener 'open', =>
			@getActivePlayers()
	
	sendRequest: (data, cb) ->
		@id++
		if cb?
			@requests[@id] = cb
		data.id = @id
		data.jsonrpc = '2.0'
		@ws.send JSON.stringify data
		
	listen: ->
		@ws.addEventListener 'message', (e) =>
			try
				data = JSON.parse e.data
				if data.result?
					if data.id isnt undefined
						if @requests[@id] isnt undefined
							@requests[@id] data.result
							delete @requests[@id]
				switch data.method
					when 'Player.OnPlay'
						@player = data.params?.data?.player?.playerid
						@emit 'play'
					when 'Player.OnStop'
						@player = null
						@emit 'stop'
					when 'Player.OnPause'
						@emit 'pause'
			catch ex
				throw ex

	getActivePlayers: ->
		@sendRequest {method: 'Player.GetActivePlayers'}, (data) =>
			if data.length > 0
				@player = data[0].playerid
			else
				@player = null
	
	sendPlayerRequest: (data, cb) ->
		if data.params is undefined
			data.params = {}
		if @player?
			data.params.playerid = @player
		@sendRequest data, cb
	
	sendPlayerButton: (button, cb) ->
		@sendPlayerRequest {method: 'Player.'+button}, cb
		
	sendButton: (method, button, cb) ->
		@sendRequest {method: method+"."+button}, cb
		
	for method, arr of buttons
		for button in arr
			do (method, button) =>
				str = button.toLowerCase().substr(0,1) + button.substr 1
				@::[str] = (cb) ->
					if method is 'Player'
						@sendPlayerButton button, cb
					else
						@sendButton method, button, cb

module.exports = XbmcClient
