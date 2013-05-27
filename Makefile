
build: components coffee
	@component build --dev

coffee: xbmc-client.coffee
	coffee -c xbmc-client.coffee

components: component.json
	@component install --dev

clean:
	rm -fr build components template.js

.PHONY: clean
