# Getting Started with MEDICUS API

Welcome to the MEDICUS API! This guide will help you get up and running with the API and perform your first medical space optimization.

## 1. Quick Setup

If you haven't set up your development environment yet, please follow the [Setup Guide](./01-setup.md).

Assuming you have the server running:
```bash
cd medicus-api
stack exec medicus-api
```

The server should now be available at `http://localhost:3000`.

## 2. Accessing GraphQL Playground

MEDICUS API provides an interactive playground for exploring the schema and executing queries.

1. Open your browser and navigate to `http://localhost:3000/playground`.
2. You will see an IDE where you can type GraphQL queries on the left and see results on the right.

## 3. Your First Query: Health Check

Verify the API is working correctly by running this query:

```graphql
query {
  health {
    status
    version
    service
    timestamp
  }
}
```

You should receive a response like this:
```json
{
  "data": {
    "health": {
      "status": "healthy",
      "version": "0.1.0",
      "service": "medicus-api",
      "timestamp": "2026-03-08T21:00:00UTC"
    }
  }
}
```

## 4. Validating a Space Configuration

Before creating a space, you can validate its parameters (dimensions and norm weights).

```graphql
query {
  validateSpace(config: {
    dimension: 3,
    normWeights: {
      lambda: 0.4,
      mu: 0.3,
      nu: 0.3
    },
    constraints: []
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

## 5. Running an Optimization

Finally, let's run a simple optimization.

```graphql
mutation {
  optimize(input: {
    objective: {
      functionType: Quadratic,
      parameters: "{}"
    },
    initialPoint: [0.1, 0.5, 0.2]
  }) {
    success
    solution
    objectiveValue
    computationTimeMs
  }
}
```

## Next Steps

- Explore all available constraints: Run `query { listAvailableConstraints }`.
- Deep dive into API details: Check the [API Reference](./08-api-reference.md).
- Follow specific tutorials in the [Tutorials](./tutorials/) directory.
