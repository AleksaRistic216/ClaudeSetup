# Data Patterns

## Entities

Location: `Contracts/Entities/`

Entities inherit from `LSCoreEntity` which provides:
- `long Id` — primary key
- `bool IsActive` — soft delete flag
- `DateTime CreatedAt` — auto-set by `Insert()`
- `long CreatedBy` — current user ID, auto-set
- `DateTime? UpdatedAt` — auto-set by `Update()`
- `long? UpdatedBy` — current user ID, auto-set

```csharp
public class ProductEntity : LSCoreEntity
{
    public string Name { get; set; }
    public string Src { get; set; }
    public decimal VAT { get; set; }
    public long ProductPriceGroupId { get; set; }
    public List<string>? SearchKeywords { get; set; }

    [NotMapped]
    public ProductPriceEntity Price { get; set; }

    [NotMapped]
    public List<ProductGroupEntity> Groups { get; set; }
}
```

- Use `[NotMapped]` for navigation properties
- No business logic in entities

## Entity Mappings

Location: `Repository/EntityMappings/` (or `DbMappings/`)

```csharp
public class ProductEntityMap : LSCoreEntityMap<ProductEntity>
{
    public override Action<EntityTypeBuilder<ProductEntity>> Mapper { get; } =
        builder =>
        {
            builder.HasIndex(x => x.Name).IsUnique();
            builder.Property(x => x.Name).IsRequired().HasMaxLength(64);

            builder
                .HasOne(x => x.Price)
                .WithOne(x => x.Product)
                .HasForeignKey<ProductPriceEntity>(x => x.ProductId);

            builder
                .Property(x => x.StockType)
                .IsRequired()
                .HasDefaultValue(ProductStockType.Standard);
        };
}
```

Register in DbContext:

```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    modelBuilder.Entity<ProductEntity>().AddMap(new ProductEntityMap());
}
```

## Repositories

Location: `Repository/Repositories/`

Repositories inherit from `LSCoreRepositoryBase<TEntity>` which provides:
- `Get(long id)` — get by ID
- `Get(Expression<Func<T, bool>> predicate)` — get by predicate
- `GetMultiple()` — all active entities (IQueryable)
- `Insert(entity)` — auto-sets IsActive, CreatedAt, CreatedBy
- `Update(entity)` — auto-sets UpdatedAt, UpdatedBy
- `SoftDelete(long id)` — sets IsActive=false
- `HardDelete(long id)` — permanently deletes
- `GetPaginated<TDto>(request)` — paginated with auto-mapping

```csharp
public class ProductRepository(WebDbContext dbContext)
    : LSCoreRepositoryBase<ProductEntity>(dbContext),
        IProductRepository
{
    public Task<Dictionary<long, ProductEntity>> GetAllAsDictionaryAsync() =>
        GetMultiple().Include(x => x.Price).ToDictionaryAsync(x => x.Id);
}
```

**Never** use raw `dbContext` for CRUD — always go through LSCore base methods.

## DTOs

Location: `Contracts/Dtos/`

Simple POCOs, no logic.

```csharp
public class ProductsGetDto
{
    public long Id { get; set; }
    public string Name { get; set; }
    public decimal Price { get; set; }
    public DateTime CreatedAt { get; set; }
}
```

## DTO Mappings

Location: `Contracts/DtoMappings/`

Implement `ILSCoreMapper<TEntity, TDto>` for custom mapping. Uses ValueInjecter.

```csharp
public class ProductDtoMapper : ILSCoreMapper<ProductEntity, ProductsGetDto>
{
    public ProductsGetDto ToMapped(ProductEntity sender)
    {
        var dto = new ProductsGetDto();
        dto.InjectFrom(sender);  // Auto-maps matching properties
        dto.Price = sender.Price?.Value ?? 0;  // Manual mapping for navigation props
        return dto;
    }
}
```

Usage in managers:

```csharp
using LSCore.Mapper.Domain;

// Single entity
var dto = entity.ToMapped<ProductEntity, ProductsGetDto>();

// Collection
var dtos = entities.ToMappedList<ProductEntity, ProductsGetDto>();

// Update entity from request
entity.UpdateMapped(request);
```

## DbContext

Location: `Common.Repository/`

```csharp
public class {ProjectName}DbContext(
    DbContextOptions<{ProjectName}DbContext> options,
    IConfigurationRoot configurationRoot
) : LSCoreDbContext<{ProjectName}DbContext>(options)
{
    public DbSet<ProductEntity> Products { get; set; }
    public DbSet<OrderEntity> Orders { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        var connectionString = DbConstants.ConnectionString(configurationRoot);
        optionsBuilder.UseNpgsql(connectionString);
        base.OnConfiguring(optionsBuilder);
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<ProductEntity>().AddMap(new ProductEntityMap());
        modelBuilder.Entity<OrderEntity>().AddMap(new OrderEntityMap());
    }
}
```

## Migrations

Location: `Common.DbMigrations/`

```bash
# Add migration
dotnet ef migrations add MigrationName --project src/{ProjectName}/{ProjectName}.Common/{ProjectName}.Common.DbMigrations

# Update database
dotnet ef database update --project src/{ProjectName}/{ProjectName}.Common/{ProjectName}.Common.DbMigrations
```

Seed data in migrations:

```csharp
protected override void Up(MigrationBuilder migrationBuilder)
{
    migrationBuilder.InsertData(
        table: "ProductGroups",
        columns: new[] { "Id", "Name", "IsActive", "CreatedAt", "CreatedBy" },
        values: new object[,]
        {
            { 1L, "Group1", true, DateTime.UtcNow, 0L },
        });
}
```
