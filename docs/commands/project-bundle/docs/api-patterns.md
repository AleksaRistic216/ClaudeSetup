# API Patterns

## Controller Structure

Controllers are thin — they delegate to managers and return results directly.

```csharp
[ApiController]
[LSCoreAuth]
[Permissions(Permission.Access)]
public class ProductsController(
    IProductManager productManager
) : ControllerBase
{
    [HttpGet]
    [Route("/products")]
    public async Task<LSCoreSortedAndPagedResponse<ProductsGetDto>> GetMultiple(
        [FromQuery] ProductsGetRequest request
    ) => await productManager.GetMultipleAsync(request);

    [HttpGet]
    [Route("/products/{id}")]
    public ProductsGetSingleDto GetSingle([FromRoute] LSCoreIdRequest request)
        => productManager.GetSingle(request);

    [HttpPut]
    [Route("/products/{id}")]
    [Permissions(Permission.Admin_Products_EditAll)]
    public long Save([FromBody] ProductsSaveRequest request)
        => productManager.Save(request);

    [HttpDelete]
    [Route("/products/{id}")]
    [Permissions(Permission.Admin_Products_EditAll)]
    public void Delete([FromRoute] LSCoreIdRequest request)
        => productManager.Delete(request);
}
```

## Routing Rules

- Resource ID in URL path: `[Route("/products/{id}")]`
- No two adjoined static segments: `/products/status` is wrong, use `/products/{id}/status`
- PUT for create-or-update (nullable `Id` in request body)
- GET for reads, PUT for create/update, DELETE for delete
- `[FromQuery]` for GET params, `[FromBody]` for PUT/POST, `[FromRoute]` for path params

## Permissions

Every controller requires:
- `[LSCoreAuth]` attribute (requires authentication)
- Class-level `[Permissions(...)]` for READ access
- Method-level `[Permissions(...)]` on PUT/POST/DELETE for WRITE access

## Request Objects

```csharp
// Simple ID request (LSCore provides this)
public class LSCoreIdRequest { public long Id { get; set; } }

// Paginated/sorted request
public class ProductsGetRequest : LSCoreSortableAndPageableRequest<ProductsSortColumnCodes.Products>
{
    public string? GroupName { get; set; }
    public string? KeywordSearch { get; set; }
    public List<long>? Ids { get; set; }
}

// Create/Update request (nullable Id = create, non-null = update)
public class ProductsSaveRequest
{
    public long? Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
}
```

## Response Format

- **Single item**: Return DTO directly
- **Multiple items**: Return `LSCoreSortedAndPagedResponse<T>`

```csharp
// LSCoreSortedAndPagedResponse contains:
// - Payload: List<T>     (the items — NOT "Items")
// - Pagination: { Page, PageSize, TotalCount, TotalPages }
```

Frontend accesses: `response.data?.payload` (not `response.data?.items`).
