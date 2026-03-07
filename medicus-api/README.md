# MEDICUS API

Web API for MEDICUS Engine - Medical Data Security Optimization

## Overview

MEDICUS APIは、MEDICUS Engine（医療データセキュリティ最適化計算エンジン）をGraphQL Web APIとして提供するプロジェクトです。YesodフレームワークとMorpheus GraphQLを使用し、型安全で自己文書化されたAPIを実現します。

## Features

- **GraphQL API** - Morpheus GraphQLによる型安全なスキーマ
- **MEDICUS Engine Integration** - 高度な数学的最適化機能
- **Type-Safe** - Haskellの型システムによるコンパイル時検証
- **Self-Documenting** - GraphQL Introspectionによる自動ドキュメント生成
- **Yesod Framework** - 堅牢なWebアプリケーション基盤

## Prerequisites

- GHC 9.2+ または Stack
- Cabal 3.6+
- MEDICUS Engine (medicus-engine library)

## Quick Start

### Build

```bash
cabal build
```

### Run

```bash
cabal run medicus-api
```

The server will start on `http://localhost:3000` by default.

### GraphQL Playground

Open `http://localhost:3000/playground` to explore the API interactively.

## Project Structure

```
medicus-api/
├── src/
│   ├── Foundation.hs          # Yesod foundation
│   ├── Settings.hs            # Configuration
│   ├── GraphQL/               # GraphQL schema & resolvers
│   ├── Handler/               # HTTP handlers
│   ├── Service/               # Business logic
│   └── Util/                  # Utilities
├── test/                      # Test suites
├── config/                    # Configuration files
├── app/Main.hs                # Entry point
└── medicus-api.cabal          # Package definition
```

## API Documentation

See [API Documentation](.cursor/specs/medicus-api/README.md) for detailed API reference.

## Development

### Run tests

```bash
cabal test
```

### Generate documentation

```bash
cabal haddock
```

### Development mode

```bash
yesod devel
```

## Configuration

Configuration files are located in `config/`:
- `settings.yml` - Development settings
- `settings-prod.yml` - Production settings
- `routes.txt` - Yesod routing

## Specifications

Detailed specifications are available in `.cursor/specs/medicus-api/`:
- `requirements.md` - Requirements
- `design.md` - Architecture & Design
- `tasks.md` - Implementation Tasks
- `future-enhancements.md` - Future Features

## License

BSD-3-Clause - See LICENSE file

## Authors

MEDICUS Research Team

## Status

🟨 **In Development** - Phase 1-3 (MVP & Core Features)

**Version:** 0.1.0  
**Last Updated:** 2026-03-07
