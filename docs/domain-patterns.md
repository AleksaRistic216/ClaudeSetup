# Domain Patterns

## Managers

Location: `Domain/Managers/`

Managers contain business logic. They are the only layer that orchestrates operations across repositories.

```csharp
public class ProductManager(
    IProductRepository productRepository,
    IOrderRepository orderRepository,
    ILogger<ProductManager> logger,
    LSCoreAuthContextEntity<string> contextEntity
) : IProductManager
{
    public async Task<LSCoreSortedAndPagedResponse<ProductsGetDto>> GetMultipleAsync(
        ProductsGetRequest request
    )
    {
        var items = productRepository.GetMultiple();
        // Filter, sort, paginate, map to DTOs
        return new LSCoreSortedAndPagedResponse<ProductsGetDto> { ... };
    }

    public long Save(ProductsSaveRequest request)
    {
        request.Validate();  // LSCore validation extension

        if (request.Id == null)
        {
            var entity = request.ToMapped<ProductsSaveRequest, ProductEntity>();
            productRepository.Insert(entity);
            return entity.Id;
        }
        else
        {
            var entity = productRepository.Get(request.Id.Value);
            entity.UpdateMapped(request);
            productRepository.Update(entity);
            return entity.Id;
        }
    }
}
```

**Rules:**
- Only public methods (matching the interface)
- No private helper methods — use static helpers in `Contracts/Helpers/`
- Constructor injection for dependencies
- Call `request.Validate()` before processing writes

## Interfaces

Location: `Contracts/Interfaces/IManagers/`

```csharp
public interface IProductManager
{
    Task<LSCoreSortedAndPagedResponse<ProductsGetDto>> GetMultipleAsync(ProductsGetRequest request);
    ProductsGetSingleDto GetSingle(LSCoreIdRequest request);
    long Save(ProductsSaveRequest request);
    void Delete(LSCoreIdRequest request);
}
```

Always update the interface before or simultaneously with the implementation.

## Validators

Location: `Domain/Validators/`

Inherit from `LSCoreValidatorBase<T>` (FluentValidation).

```csharp
public class ProductsSaveRequestValidator : LSCoreValidatorBase<ProductsSaveRequest>
{
    public ProductsSaveRequestValidator(IWebDbContextFactory dbContextFactory)
    {
        RuleFor(x => x.Name)
            .NotEmpty()
            .WithMessage(ProductValidationCodes.PVC_001.GetDescription())
            .MaximumLength(64)
            .WithMessage(ProductValidationCodes.PVC_002.GetDescription());

        RuleFor(x => x.Id)
            .Custom((id, context) =>
            {
                if (id != null && !dbContextFactory
                    .Create<WebDbContext>()
                    .Products.Any(x => x.Id == id && x.IsActive))
                {
                    context.AddFailure(ProductValidationCodes.PVC_003.GetDescription());
                }
            });
    }
}
```

**Validation codes**: Located in `Contracts/Enums/ValidationCodes/`, enum with `[Description]`.

```csharp
public enum ProductValidationCodes
{
    [Description("Naziv je obavezan.")]
    PVC_001,

    [Description("Naziv mora biti kraci od {0} karaktera.")]
    PVC_002,
}
```

## Static Helpers

Location: `Contracts/Helpers/`

```csharp
public static class ProductsHelpers
{
    public static decimal CalculatePriceK(decimal min, decimal max)
    {
        return max - min;
    }

    public static CheckoutRequest ToCheckoutRequest(
        this CheckoutRequestBase request,
        IHttpContextAccessor httpContextAccessor
    )
    {
        var checkoutRequest = new CheckoutRequest();
        checkoutRequest.InjectFrom(request);
        checkoutRequest.IsAuthenticated =
            httpContextAccessor.HttpContext.User.Identity?.IsAuthenticated ?? false;
        return checkoutRequest;
    }
}
```
