all: install

# install TBXark/mcp-proxy
.PHONY: install-proxy
install-proxy:
	go install github.com/TBXark/mcp-proxy@latest

# put config.json with 1Password CLI
# https://developer.1password.com/docs/cli/reference/commands/inject
.PHONY: config.json
config.json:
	export REPOSITORY=$$(pwd) && op inject --account=my.1password.com -i config.template.json | envsubst > config.json
	chmod 600 config.json

# generate plist file for LaunchAgent
.PHONY: mcp-proxy.plist
mcp-proxy.plist:
	# paths for npx & uvx
	NODE_BIN=$$(mise where node)/bin && \
	UVX_PATH=$$(brew --prefix uv)/bin && \
	LAUNCHD_PATH=$$NODE_BIN:$$UVX_PATH:/usr/local/bin:/usr/bin:/bin \
	COMMAND_PATH=$$(which mcp-proxy) \
	REPOSITORY=$$(pwd) \
	envsubst < mcp-proxy.template.plist > mcp-proxy.plist

# register mcp-proxy as LaunchAgent
.PHONY: install-agent
install-agent: config.json mcp-proxy.plist
	cp mcp-proxy.plist ~/Library/LaunchAgents/mcp-proxy.plist
	launchctl unload -w ~/Library/LaunchAgents/mcp-proxy.plist 2>/dev/null || true
	launchctl load -w ~/Library/LaunchAgents/mcp-proxy.plist

.PHONY: install
install: install-proxy install-agent

# restart mcp-proxy LaunchAgent
.PHONY: restart
restart:
	launchctl unload -w ~/Library/LaunchAgents/mcp-proxy.plist
	launchctl load -w ~/Library/LaunchAgents/mcp-proxy.plist
	exec tail -f ~/logs/mcp-proxy.error.log

# unload mcp-proxy LaunchAgent
.PHONY: unload
unload:
	launchctl unload -w ~/Library/LaunchAgents/mcp-proxy.plist
	rm ~/Library/LaunchAgents/mcp-proxy.plist

# create symlink to presets directory
.PHONY: link-presets
link-presets:
	rm -rf ~/mcp-presets
	ln -sf $(PWD)/presets ~/mcp-presets
