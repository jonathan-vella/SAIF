---
post_title: "SAIF Bicep Modules"
author1: "SAIF Team"
post_slug: "saif-bicep-modules"
microsoft_alias: "saifteam"
featured_image: ""
categories: ["Infrastructure", "Azure"]
tags: ["Bicep", "IaC", "Modules", "Azure"]
ai_note: "Content generated with AI assistance and reviewed by maintainers."
summary: "Overview of local Bicep modules used by SAIF and their inputs/outputs."
post_date: "2025-09-03"
---

## Module overview

This folder contains small, single-purpose Bicep modules. Each module has clear inputs (params) and outputs, used by `infra/main.bicep`.

### Observability
- File: `observability/logging.bicep`
- Purpose: Creates Log Analytics and Application Insights (workspace-based)
- Inputs:
  - `location` (string)
  - `tags` (object)
  - `logAnalyticsName` (string)
  - `appInsightsName` (string)
  - `workspaceSku` (string, default `PerGB2018`)
  - `retentionInDays` (int, default `30`)
- Outputs:
  - `logAnalyticsId` (string)
  - `appInsightsConnectionString` (string) — sensitive, avoid surfacing from root

### Container Registry
- File: `container/registry.bicep`
- Purpose: Creates an ACR
- Inputs: `name`, `location`, `tags`, `skuName` (default `Standard`), `adminUserEnabled` (bool)
- Outputs: `id`, `name`, `loginServer`

### Web Plan
- File: `web/plan.bicep`
- Purpose: Linux App Service Plan
- Inputs: `name`, `location`, `tags`, `skuName`, `skuTier`
- Outputs: `id`, `name`

### Web Site (container)
- File: `web/site.bicep`
- Purpose: Linux Web App running a container image
- Inputs: `name`, `location`, `tags`, `serverFarmId`, `image`, `websitesPort` (default `80`), `healthCheckPath` (default `/`), `appSettings` (array)
- Outputs: `id`, `name`, `defaultHostName`, `principalId`

### SQL Server
- File: `sql/server.bicep`
- Purpose: SQL logical server (public network enabled for training)
- Inputs: `name`, `location`, `tags`, `administratorLogin`, `administratorLoginPassword` (secure)
- Outputs: `id`, `name`, `fullyQualifiedDomainName`

### SQL Database
- File: `sql/database.bicep`
- Purpose: Database on the logical server
- Inputs: `location`, `tags`, `serverName`, `name`, `skuName`, `skuTier`, `collation`
- Outputs: `id`, `dbName`

### SQL Firewall Allow Azure
- File: `sql/firewallAllowAzure.bicep`
- Purpose: Adds the `0.0.0.0` rule to allow Azure Services
- Inputs: `serverName`, `name` (default `AllowAzureServices`)
- Outputs: `id`, `ruleName`

## Notes
- Diagnostics: Root template attaches diagnostic settings for API/Web and SQL to the Log Analytics workspace.
- Security: This repo is an intentionally vulnerable training app. See comments/TODOs for secure alternatives.
- Conventions: Names follow SAIF suffix pattern using `uniqueString(resourceGroup().id)`.
