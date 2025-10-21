mcp-configs
===

@pokutuna の個人的な MCP サーバー設定

- [TBXark/mcp-proxy](https://github.com/TBXark/mcp-proxy) を利用して接続を集約する
- `config.template.json` にシークレットを 1Password CLI で埋める
- パス等を `mcp-proxy.template.plist` を埋めて LaunchAgents に登録する
  - Makefile 中のパスを調整してください

## install

`$ make install`

## 設定

`http://localhost:7683/{NAME}/mcp` で各 MCP サーバーに接続できます


### ~/.claude.json 設定例

設定は `config.json` に集約し、利用側では単に URL を指定するだけにします

```jsonc
{
  // ...
  "mcpServers": {
    "deepwiki": {
      "type": "http",
      "url": "http://localhost:7683/deepwiki/mcp"
    },
    "chrome-tabs": {
      "type": "http",
      "url": "http://localhost:7683/chrome-tabs/mcp"
    },
    "google-search": {
      "type": "http",
      "url": "http://localhost:7683/google-search/mcp"
    }
  },
  // ...
}
```

### presets

コンテキストに余計なものを乗せないよう、常用しない MCP サーバは `presets/` 以下に定義しておいて `claude --mcp-config=` で指定して必要なときだけ設定します。

`$ make link-presets` で `~/mcp-presets` にシンボリックリンクを作成できるので

`$ claude --mcp-config=$HOME/mcp-presets/devtools.json`

## 注意

- 2025-10 現在 Resource の listChanged イベント等は MCP Proxy 経由では配信されません
