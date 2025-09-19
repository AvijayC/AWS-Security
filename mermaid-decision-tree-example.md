# Mermaid Decision Tree Example

## Simple Decision Tree

```mermaid
graph TD
    A[Start: Need AWS Storage?] --> B{Is data frequently accessed?}
    B -->|Yes| C{Need real-time access?}
    B -->|No| D{Archive for compliance?}
    
    C -->|Yes| E[Use S3 Standard]
    C -->|No| F[Use S3 Infrequent Access]
    
    D -->|Yes| G{Retrieval time requirement?}
    D -->|No| H[Use S3 Intelligent-Tiering]
    
    G -->|Minutes| I[Use Glacier Instant Retrieval]
    G -->|Hours| J[Use Glacier Flexible]
    G -->|12+ Hours| K[Use Glacier Deep Archive]
    
    E --> L[End: Storage Selected]
    F --> L
    H --> L
    I --> L
    J --> L
    K --> L
```

## Key Syntax Elements

- `graph TD` - Top Down flow (can also use LR for Left-Right)
- `[Rectangle]` - Regular node with text
- `{Diamond}` - Decision node (rhombus shape)
- `-->` - Arrow connector
- `-->|Label|` - Arrow with label text
- Letters (A, B, C) - Node IDs for referencing

## Other Common Shapes

```mermaid
graph LR
    A[Rectangle] --> B((Circle))
    B --> C{Diamond}
    C --> D[/Parallelogram/]
    D --> E[\Trapezoid\]
    E --> F[(Database)]
```