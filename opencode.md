# Deploy Agent - Portfolio Deployment

## Description

When user asks to deploy (e.g., `/deploy prod`, `/deploy dev`), execute the deployment workflow:

## Usage

```
/deploy <env>
```

Where `<env>` is: local, dev, staging, or prod

## Workflow

1. **Accept ENV** - Validate it's one of: local, dev, staging, prod
2. **Fetch latest tags** - Get latest image tags from DockerHub:
   ```bash
   curl -s "https://hub.docker.com/v2/repositories/ossemaabd95/stackvault/tags?page_size=10" | jq -r '.results[:10][] | "\(.name) (\(.last_updated))"'
   ```
3. **Show current tags** - Read .env.{env} to show current BACKEND_TAG and FRONT_TAG
4. **Ask confirmation** - Show new vs current tags, ask "Update and deploy?"
5. **Update env file** - If confirmed, update BACKEND_TAG and FRONT_TAG in .env.{env}
6. **Deploy** - Run: `make up ENV={env}`

## Implementation Details

### Read current tags

Read `.env.{env}` file using the Read tool.

### Update tags

Use Edit tool to replace:
- `BACKEND_TAG=.*` → `BACKEND_TAG={new_tag}`
- `FRONT_TAG=.*` → `FRONT_TAG={new_tag}`

### Deploy

Run via bash:
```bash
make up ENV={env}
```

## Examples

- `/deploy local` - Deploy to local
- `/deploy dev` - Deploy to dev
- `/deploy staging` - Deploy to staging  
- `/deploy prod` - Deploy to prod

## Notes

- Valid envs: local, dev, staging, prod
- DockerHub: ossemaabd95/stackvault
- Same tag for front and back
- For local: uses .env.secrets.local for certs
- For others: loads SSL certs from OCI Vault