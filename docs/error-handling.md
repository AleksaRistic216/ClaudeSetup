# Error Handling

## LSCore Exceptions

Use LSCore exception types for standard HTTP error responses:

```csharp
throw new LSCoreNotFoundException();       // 404
throw new LSCoreBadRequestException();     // 400
throw new LSCoreUnauthorizedException();   // 401
throw new LSCoreForbiddenException();      // 403
```

## Usage in Managers

```csharp
public ProductsGetSingleDto GetSingle(LSCoreIdRequest request)
{
    var entity = productRepository.GetOrDefault(request.Id);
    if (entity == null)
        throw new LSCoreNotFoundException();

    return entity.ToMapped<ProductEntity, ProductsGetSingleDto>();
}
```

## Middleware Registration

Register the LSCore exception handler in `Program.cs`:

```csharp
app.UseLSCoreExceptions();
```

This catches all LSCore exceptions and returns proper HTTP status codes with structured error responses.

## Validation Errors

Validation failures (via `request.Validate()`) are automatically handled by LSCore and return 400 Bad Request with validation messages.

## Logging Errors

For non-LSCore exceptions that need logging:

```csharp
public class ProductManager(ILogger<ProductManager> logger) : IProductManager
{
    public void ProcessOrder(OrderRequest request)
    {
        try
        {
            // business logic
        }
        catch (Exception e)
        {
            logger.LogError(e.ToString());
            throw;
        }
    }
}
```
