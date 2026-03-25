# Sorting and Pagination

## Sort Column Enum

Location: `Contracts/Enums/SortColumnCodes/`

Define a static class with an inner enum and a dictionary mapping enum values to entity expressions.

```csharp
public static class ProductsSortColumnCodes
{
    public enum Products
    {
        Id = 0,
        Name = 1,
        CreatedAt = 2,
    }

    public static Dictionary<
        Products,
        Expression<Func<ProductEntity, object>>
    > ProductsSortRules = new()
    {
        { Products.Id, x => x.Id },
        { Products.Name, x => x.Name },
        { Products.CreatedAt, x => x.CreatedAt },
    };
}
```

## Request

Extend `LSCoreSortableAndPageableRequest<TSortEnum>`:

```csharp
public class ProductsGetRequest : LSCoreSortableAndPageableRequest<ProductsSortColumnCodes.Products>
{
    public string? Filter { get; set; }
    public List<long>? GroupIds { get; set; }
}
```

LSCore base provides:
- `CurrentPage` (1-based, not 0-based)
- `PageSize`
- `SortColumn` (typed enum)
- `SortDirection` (`ListSortDirection`: Ascending=0, Descending=1)

## Manager Implementation

```csharp
using System.ComponentModel;

public async Task<LSCoreSortedAndPagedResponse<ProductsGetDto>> GetMultipleAsync(
    ProductsGetRequest request)
{
    var query = productRepository.GetMultiple();

    // Apply filters
    if (!string.IsNullOrWhiteSpace(request.Filter))
        query = query.Where(x => x.Name.Contains(request.Filter));

    // Map to DTOs
    var items = query.ToMappedList<ProductEntity, ProductsGetDto>();

    // Sort
    var descending = request.SortDirection == ListSortDirection.Descending;
    IEnumerable<ProductsGetDto> sorted = request.SortColumn switch
    {
        ProductsSortColumnCodes.Products.Name => descending
            ? items.OrderByDescending(x => x.Name)
            : items.OrderBy(x => x.Name),
        _ => descending
            ? items.OrderByDescending(x => x.CreatedAt)
            : items.OrderBy(x => x.CreatedAt),
    };

    // Paginate
    var totalCount = sorted.Count();
    var page = sorted
        .Skip((request.CurrentPage - 1) * request.PageSize)
        .Take(request.PageSize)
        .ToList();

    return new LSCoreSortedAndPagedResponse<ProductsGetDto>
    {
        Payload = page,
        Pagination = new LSCorePaginationInfo
        {
            Page = request.CurrentPage,
            PageSize = request.PageSize,
            TotalCount = totalCount,
            TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize),
        }
    };
}
```

## Frontend Usage

```javascript
const response = await mainApi.get('/products', {
    params: {
        CurrentPage: 1,
        PageSize: 25,
        SortColumn: 0,       // enum integer value
        SortDirection: 0,     // 0=Ascending, 1=Descending
        Filter: 'search term'
    }
});

const items = response.data?.payload ?? [];
const pagination = response.data?.pagination;
```
