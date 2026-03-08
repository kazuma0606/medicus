# MEDICUS API Reference

This document provides a detailed reference for the MEDICUS GraphQL API.

## Queries

### `health`
Returns the current status of the API service.

**Response Type:** `HealthStatus`
- `status`: String (e.g., "healthy")
- `service`: String ("medicus-api")
- `version`: String (e.g., "0.1.0")
- `timestamp`: String (ISO-8601)

### `listAvailableConstraints`
Lists all medical and security constraint types supported by the engine.

**Response Type:** `[ConstraintType!]`
- `PrivacyProtection`
- `EmergencyAccess`
- `SystemAvailability`
- `RegulatoryCompliance`
- `CustomConstraint`

### `validateSpace`
Validates a potential space configuration without creating a resource.

**Arguments:**
- `config`: `SpaceConfigInput!`

**Response Type:** `ValidationResult`

---

## Mutations

### `createSpace`
Creates a new MEDICUS space based on the provided configuration.

**Arguments:**
- `csConfig`: `SpaceConfigInput!`

**Response Type:** `CreateSpaceResult`

### `optimize`
Executes a single optimization process.

**Arguments:**
- `input`: `OptimizationInput!`

**Response Type:** `OptimizationResult`

### `optimizeBatch`
Executes multiple optimization processes in a single request.

**Arguments:**
- `batchInput`: `BatchOptimizationInput!`

**Response Type:** `[OptimizationResult!]`

---

## Input Types

### `SpaceConfigInput`
- `dimension`: Int (1 to 1000)
- `normWeights`: `NormWeightsInput!`
- `constraints`: `[ConstraintInput!]`

### `OptimizationInput`
- `objective`: `ObjectiveFunctionInput!`
- `initialPoint`: `[Float!]`
- `options`: `OptimizationOptions`
