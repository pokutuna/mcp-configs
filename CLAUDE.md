# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

このリポジトリは MCP (Model Context Protocol) サーバー設定を管理します。[TBXark/mcp-proxy](https://github.com/TBXark/mcp-proxy) を利用して複数の MCP サーバー接続を単一のプロキシ経由で集約し、macOS の LaunchAgent として常駐させます。

## Architecture

### Core Components

1. **mcp-proxy**: すべての MCP サーバーへのアクセスを集約するプロキシ (`http://localhost:7683`)
2. **config.template.json**: MCP サーバーの設定テンプレート (1Password CLI でシークレットを注入)
3. **config.json**: 生成された実際の設定ファイル (git 管理外、シークレットを含む)
4. **presets/**: 用途別の MCP サーバー設定プリセット (コンテキストを軽量に保つため)

### Configuration Flow

```
config.template.json → (1Password CLI: op inject) → config.json → mcp-proxy → MCP servers
```

- `config.template.json` 内の `{{ op://... }}` プレースホルダーが 1Password CLI で実際の値に置換されます
- mcp-proxy が `config.json` を読み込み、各 MCP サーバーへの接続を管理します
- クライアント (Claude Code等) は `http://localhost:7683/{SERVER_NAME}/mcp` で各サーバーにアクセスします

### Presets System

常用しない MCP サーバーは `presets/` 以下に定義し、必要なときだけ `claude --mcp-config=$HOME/mcp-presets/{preset}.json` で指定します。

**既存のプリセット:**
- `browser.json`: playwright サーバー
- `devtools.json`: chrome-devtools サーバー
- `langchain.json`: docs-langchain サーバー

**プリセットの設計原則:**
- 必要最小限 (1-2 個) の MCP サーバーのみ含める
- ユーザーが明示的にリクエストしない限り、最小構成を優先する

## Common Commands

### Initial Setup
```bash
make install          # mcp-proxy をインストールし、LaunchAgent として登録
```

### Configuration Management
```bash
make config.json      # 1Password CLI で config.template.json からシークレットを注入
make mcp-proxy.plist  # LaunchAgent 用の plist ファイルを生成
make install-agent    # config.json と plist を生成し、LaunchAgent に登録
```

### Service Management
```bash
make restart          # mcp-proxy サービスを再起動してログを tail
make unload           # LaunchAgent から mcp-proxy を削除
```

### Presets
```bash
make link-presets     # ~/mcp-presets にシンボリックリンクを作成
claude --mcp-config=$HOME/mcp-presets/devtools.json  # プリセットを指定して起動
```

## Specialized Agents

このリポジトリには 2 つの専用エージェントが定義されています:

### mcp-preset-generator
新しいプリセット設定を作成・更新します。必要最小限 (1-2 個) の MCP サーバーのみを含めることを優先します。

### mcp-server-configurator
新しい MCP サーバーを調査し、セキュリティ評価を行い、`config.template.json` に設定を追加します。実行方法 (Docker/npx/uvx) の選択、セキュリティリスクの評価、必要な権限の文書化を行います。

## Important Notes

### Security and Secrets
- `config.json` は git 管理外です (シークレットを含むため)
- `config.template.json` を編集する際は、シークレットを `{{ op://Private/... }}` 形式で 1Password CLI の参照として記述します
- シークレットを直接コミットしないでください

### MCP Proxy Limitations
- 2025-10 現在、Resource の `listChanged` イベント等は MCP Proxy 経由では配信されません

### Path Configuration
- Makefile 内のパス (NODE_BIN, UVX_PATH) は環境に応じて調整が必要な場合があります
- mise と Homebrew を使用してツールのパスを解決しています

## Configuration Format

### config.template.json Structure
```json
{
  "mcpProxy": {
    "baseURL": "http://localhost:7683",
    "addr": ":7683",
    // ... proxy settings
  },
  "mcpServers": {
    "server-name": {
      "command": "...",      // or "transportType": "streamable-http"
      "args": [...],
      "env": {...}
    }
  }
}
```

### Preset Format
```json
{
  "mcpServers": {
    "server-name": {
      "type": "http",
      "url": "http://localhost:7683/{server-name}/mcp"
    }
  }
}
```

## Client Configuration Example

`~/.claude.json` に以下のように設定して使用します:

```jsonc
{
  "mcpServers": {
    "deepwiki": {
      "type": "http",
      "url": "http://localhost:7683/deepwiki/mcp"
    },
    "chrome-tabs": {
      "type": "http",
      "url": "http://localhost:7683/chrome-tabs/mcp"
    }
  }
}
```
