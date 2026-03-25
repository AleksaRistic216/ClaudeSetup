# Backend Rules

Critical rules that must always be followed in every .NET backend project.

## Always Update Interfaces

When modifying a manager implementation, always update the corresponding interface first (or simultaneously).

- Interface: `Contracts/Interfaces/IManagers/IProductManager.cs`
- Implementation: `Domain/Managers/ProductManager.cs`

## No Private Helpers in Managers

Managers must only contain public methods (matching their interface). Extract reusable logic into static helper classes in `Contracts/Helpers/` and pass dependencies as method parameters.

```csharp
// WRONG - private method in manager
public class ProductManager : IProductManager
{
    private decimal CalculatePrice(decimal min, decimal max) => max - min;
}

// CORRECT - static helper in Contracts/Helpers/
public static class ProductsHelpers
{
    public static decimal CalculatePrice(decimal min, decimal max) => max - min;
}
```

## Always Use LSCore Repository Methods

Never use raw `dbContext` for CRUD operations. LSCore base methods auto-set audit fields.

```csharp
// WRONG - bypasses LSCore field initialization
dbContext.Products.Add(entity);
dbContext.SaveChanges();

// CORRECT
productRepository.Insert(entity);
```

- `Insert()` auto-sets `IsActive=true`, `CreatedAt`, `CreatedBy`
- `Update()` auto-sets `UpdatedAt`, `UpdatedBy`
- `SoftDelete()` sets `IsActive=false`

## Permissions on Every Endpoint

Every controller must have `[LSCoreAuth]` + class-level READ permission. Every PUT/POST/DELETE must have method-level WRITE permission.

```csharp
[ApiController]
[LSCoreAuth]
[Permissions(Permission.Access)]  // Class-level READ
public class ProductsController : ControllerBase
{
    [HttpPut]
    [Permissions(Permission.Admin_Products_EditAll)]  // Method-level WRITE
    public long Save([FromBody] ProductsSaveRequest request) { ... }
}
```

## Add Enums at the END Only

Permission and other integer-backed enums are stored as integers in the database. Inserting in the middle corrupts existing data. Always append new values at the end.

## REST Routing Standards

- Resource ID in URL path: `/products/{id}`
- No two adjoined static parts: `/products/status` is WRONG, use `/products/{id}/status`
- PUT for create-or-update with nullable `Id` in request body
- GET, PUT, POST, DELETE methods only
- Query params for filtering/pagination

## Paginated Response Uses `payload`

Frontend accesses paginated data via `response.data?.payload`, NOT `response.data?.items`.
