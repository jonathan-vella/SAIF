---
description: 'Infrastructure as Code with Bicep'
applyTo: '**/*.bicep'
---

## Naming Conventions

-   When writing Bicep code, use lowerCamelCase for all names (variables, parameters, resources)
-   Use resource type descriptive symbolic names (e.g., 'storageAccount' not 'storageAccountName')
-   Avoid using 'name' in a symbolic name as it represents the resource, not the resource's name
-   Avoid distinguishing variables and parameters by the use of suffixes

## Structure and Declaration

-   Always declare parameters at the top of files with @description decorators
-   Use latest stable API versions for all resources
-   Use descriptive @description decorators for all parameters
-   Specify minimum and maximum character length for naming parameters

## Parameters

-   Set default values that are safe for test environments (use low-cost pricing tiers)
-   Use @allowed decorator sparingly to avoid blocking valid deployments
-   Use parameters for settings that change between deployments

## Variables

-   Variables automatically infer type from the resolved value
-   Use variables to contain complex expressions instead of embedding them directly in resource properties

## Resource References

-   Use symbolic names for resource references instead of reference() or resourceId() functions
-   Create resource dependencies through symbolic names (resourceA.id) not explicit dependsOn
-   For accessing properties from other resources, use the 'existing' keyword instead of passing values through outputs

## Resource Names

-   Use template expressions with uniqueString() to create meaningful and unique resource names
-   Add prefixes to uniqueString() results since some resources don't allow names starting with numbers

## Child Resources

-   Avoid excessive nesting of child resources
-   Use parent property or nesting instead of constructing resource names for child resources

## Security

-   Never include secrets or keys in outputs
-   Use resource properties directly in outputs (e.g., storageAccount.properties.primaryEndpoints)

## Documentation

-   Include helpful // comments within your Bicep files to improve readability

## Modules and Composition

-   Use modules to group tightly related resources into small, reusable units (local files in this repo).
-   Prefer local modules over registries. Reference with forward slashes: `module api './modules/web/site.bicep' = { ... }`.
-   Keep modules single‑purpose: plan, site, registry, sql-server, sql-database, sql-firewall, diagnostics, role assignments.
-   Suggested layout:
	-   `infra/modules/observability/logging.bicep` (Log Analytics + App Insights)
	-   `infra/modules/container/registry.bicep` (ACR)
	-   `infra/modules/web/plan.bicep` (App Service Plan Linux)
	-   `infra/modules/web/site.bicep` (Linux Web App container host)
	-   `infra/modules/sql/server.bicep`, `infra/modules/sql/database.bicep`, `infra/modules/sql/firewallAllowAzure.bicep`
	-   `infra/modules/security/roleAcrPull.bicep`

## Module Contract (Inputs/Outputs/Rules)

-   Inputs: only what’s required (names, location, tags, IDs). Pass IDs and simple values, not whole resource objects.
-   Outputs: expose only stable values needed by callers (ids, names, hostnames). Never output secrets.
-   No hidden dependencies: modules don’t reference external resources; accept them as inputs.
-   Consistency: every module parameter has `@description`; apply constraints (`@minLength`, `@allowed`) where helpful.

## Main Template Responsibilities

-   Derive names, tags, env‑wide parameters (SKUs, retention), and compose modules.
-   Centralize cross‑cutting concerns (diagnosticSettings, RBAC role assignments, conditional features by environment).
-   Keep module APIs generic; avoid environment‑specific logic inside modules.

## Diagnostics as Code

-   Add `Microsoft.Insights/diagnosticSettings` for:
	-   Web Apps (API/Web) → Log Analytics workspace
	-   SQL Server (auditing/diagnostics) → Log Analytics workspace
-   Prefer a tiny diagnostics module for reuse; ensure categories/metrics are consistently enabled.

## Parameterization and Validation

-   Promote changeable settings to parameters with safe defaults:
	-   App Service Plan SKU (e.g., `P1v3`), ACR SKU (e.g., `Standard`)
	-   Log Analytics retention (e.g., 30 days)
	-   SQL DB SKU (e.g., `S1`/`Standard`), collation
	-   Container image tags (e.g., `apiImageTag`, `webImageTag`)
	-   Health check paths and ports (e.g., `websitesPort`, `healthCheckPath`)
-   Decorate public parameters with `@description`, and use constraints where reasonable.

## Secrets and Outputs

-   Never output secrets (connection strings, passwords).
-   For SAIF, insecure app settings are intentionally present for training. Add `TODO` comments with secure alternatives (Key Vault references).

## SAIF‑Specific Notes (Preserve Educational Vulnerabilities)

-   Keep public SQL access (`publicNetworkAccess: 'Enabled'`) and the 0.0.0.0 firewall rule in the training baseline.
-   Keep plaintext app settings for SQL credentials in the baseline.
-   Add `TODO` secure alternatives (not enabled by default):
	-   Use Azure Key Vault + App Settings references for secrets
	-   Use Private Endpoint for SQL and Web App VNet integration
	-   Prefer Entra ID authentication for SQL over SQL logins
-   For Linux container Web Apps:
	-   Set `WEBSITES_PORT` when container listens on a non‑80 port (API uses 8000)
	-   Add `siteConfig.healthCheckPath` (e.g., `/api/healthcheck` for API, `/` for Web)
	-   Consider `minimumTlsVersion = '1.2'` and `ftpsState = 'Disabled'`

## Minimal Examples (Concise)

// modules/web/site.bicep (skeleton)
// params: name, location, tags, serverFarmId, image, websitesPort, healthCheckPath, appSettings (array)
// outputs: id, name, defaultHostName, principalId

// main.bicep (call pattern)
// module plan './modules/web/plan.bicep' = { name: 'plan'; params: { ... } }
// module api  './modules/web/site.bicep' = { name: 'api';  params: { serverFarmId: plan.outputs.id, image: '${acrLoginServer}/saif/api:${apiImageTag}', websitesPort: 8000, healthCheckPath: '/api/healthcheck', appSettings: [...] } }
// module web  './modules/web/site.bicep' = { name: 'web';  params: { serverFarmId: plan.outputs.id, image: '${acrLoginServer}/saif/web:${webImageTag}', healthCheckPath: '/', appSettings: [...] } }

## Tagging and Defaults

```bicep
var _defaultTags_ = union(__tags__, {
  Environment: __environment__
  Owner: 'Jonathan Vella'
  CreatedBy: 'Bicep'
  LastModified: utcNow('yyyy-MM-dd')
  Application: 'SAIF'
})
```

## Quality Gates

-   Build and lint: `bicep build` on root and modules; fix API drifts immediately.
-   Preview changes: use `what-if` before production deployments.
-   Keep module APIs stable; document any breaking changes and version modules if needed.