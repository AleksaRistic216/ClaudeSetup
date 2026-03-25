# Permissions

## Permission Enum

Location: `Common.Contracts/Enums/Permission.cs`

Integer-backed enum. **Always add new values at the END** — inserting in the middle corrupts database mappings.

```csharp
public enum Permission
{
    [Description("Pristup aplikaciji")]
    Access,

    [PermissionGroup(LegacyConstants.PermissionGroup.NavBar)]
    [PermissionGroup(LegacyConstants.PermissionGroup.Products)]
    [Description("Admin - Proizvodi - Pristup modulu")]
    Admin_Products_Access,

    [PermissionGroup(LegacyConstants.PermissionGroup.Products)]
    [Description("Admin - Proizvodi - Moze da menja sve proizvode")]
    Admin_Products_EditAll,

    // ... ALWAYS add new permissions at END
}
```

## Permission Groups

Location: `Common.Contracts/Constants/`

```csharp
public static class LegacyConstants
{
    public static class PermissionGroup
    {
        public const string NavBar = "nav-bar";
        public const string Products = "products";
        public const string Orders = "orders";
    }
}
```

## Usage on Controllers

Class-level for READ access, method-level for WRITE access:

```csharp
[ApiController]
[LSCoreAuth]
[Permissions(Permission.Access, Permission.Admin_Products_Access)]
public class ProductsController : ControllerBase
{
    [HttpGet]
    [Route("/products")]
    public LSCoreSortedAndPagedResponse<ProductsGetDto> GetMultiple(
        [FromQuery] ProductsGetRequest request) { ... }

    [HttpPut]
    [Route("/products/{id}")]
    [Permissions(Permission.Admin_Products_EditAll)]  // Additional WRITE permission
    public long Save([FromBody] ProductsSaveRequest request) { ... }

    [HttpDelete]
    [Route("/products/{id}")]
    [Permissions(Permission.Admin_Products_EditAll)]
    public void Delete([FromRoute] LSCoreIdRequest request) { ... }
}
```

## Rules

- `[LSCoreAuth]` is required on every controller (enforces authentication)
- Class-level `[Permissions(...)]` is checked on every request (READ gate)
- Method-level `[Permissions(...)]` is additive (WRITE gate for mutations)
- Every GET requires at least one class-level permission
- Every PUT/POST/DELETE requires at least one method-level permission
