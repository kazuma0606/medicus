# Tutorial: Applying Medical Constraints

This tutorial guides you through applying specific medical and security constraints to your optimization space.

## Prerequisites

- API is running (see [Getting Started](../getting-started.md))
- Understanding of MEDICUS space dimensions

## 1. What are Constraints?

Constraints in MEDICUS represent medical safety boundaries, privacy requirements, or regulatory rules. Each constraint has:
- `constraintType`: The predefined category.
- `threshold`: A numerical value representing the strictness or boundary.
- `description`: A human-readable note.

## 2. Listing Available Constraints

Run this query to see what the engine currently supports:

```graphql
query {
  listAvailableConstraints
}
```

## 3. Creating a Space with Constraints

Let's create a 3-dimensional space with Privacy and Emergency Access constraints.

```graphql
mutation {
  createSpace(csConfig: {
    dimension: 3,
    normWeights: {
      lambda: 0.4,
      mu: 0.3,
      nu: 0.3
    },
    constraints: [
      {
        constraintType: PrivacyProtection,
        threshold: 0.8,
        description: "High privacy requirement for genomic data"
      },
      {
        constraintType: EmergencyAccess,
        threshold: 0.2,
        description: "Minimal latency for emergency decryption"
      }
    ]
  }) {
    spaceId
    success
    message
  }
}
```

## 4. Validating Constraints

If you want to check if your thresholds are valid without creating a resource:

```graphql
query {
  validateSpace(config: {
    dimension: 3,
    normWeights: { lambda: 0.5, mu: 0.5, nu: 0.0 },
    constraints: [
      {
        constraintType: PrivacyProtection,
        threshold: -0.1, # Invalid: threshold must be >= 0
        description: "Invalid example"
      }
    ]
  }) {
    valid
    errors {
      field
      errorMessage
      errorCode
    }
  }
}
```

The response will explain that the threshold must be non-negative.

## Next Steps

- Learn how to run optimizations in this space using the `optimize` mutation.
- Explore batch processing for multiple patient data points.
