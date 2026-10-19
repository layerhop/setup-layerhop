# setup-layerhop

Starts a local mock [LayerHop](https://layerhop.com) API in your GitHub Actions job, so integration
tests can run the whole swap flow (quote, build, report, status, webhooks) without network access
to LayerHop, an API key or real funds. It exports `LAYERHOP_API_URL`, which the LayerHop SDKs and
CLI read.

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 22 }
      - uses: layerhop/setup-layerhop@v1
        with:
          webhook-url: http://localhost:3000/api/layerhop-webhooks   # optional
      - run: npm ci && npm test   # your tests use process.env.LAYERHOP_API_URL
```

The mock is deterministic: fixed prices, an `amount` ending in `4001` refunds, `4002` fails and
`4004` returns `NO_ROUTE`; anything else fills `fill-after` seconds after it is reported. Built
transactions are placeholders that move no funds. Never broadcast them.

| Input | Default | |
|---|---|---|
| `port` | `8787` | Port of the mock API |
| `cli-version` | `latest` | `@layerhop/cli` version run with `npx` |
| `cli` | | Command to run instead of `npx` (e.g. a local build) |
| `fill-after` | `1` | Seconds until a reported order is final |
| `webhook-url` | | Where to POST signed order webhooks |
| `webhook-secret` | random | Signing secret, exported as `LAYERHOP_WEBHOOK_SECRET` |
| `fork` | `false` | Also start Anvil forks (install Foundry first) |
| `fork-chains` | `base,arbitrum` | Chains to fork |
| `timeout` | `60` | Seconds to wait for the API |

Outputs: `api-url`, `webhook-secret`. Docs: https://docs.layerhop.com/guides/local-development

Questions and bugs: open an issue in this repository or email dev@layerhop.com.
