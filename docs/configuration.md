# Configuration

## Configuration Sources (in order)

1. `appsettings.json` — local/default settings
2. Environment variables — runtime overrides
3. Vault — secrets via `AddVault<SecretsDto>()`

```csharp
builder.Configuration
    .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables();
```

## Common Environment Variables

- `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_USER`, `POSTGRES_PASSWORD` — database
- `DEPLOY_ENV` — development, staging, production
- `JWT_KEY` — JWT signing key
- `MINIO_HOST`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_PORT` — object storage
- `REDIS_*` — Redis configuration
- `OTEL_EXPORTER_OTLP_ENDPOINT` — OpenTelemetry endpoint

## Database Configuration

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    var stringBuilder = new NpgsqlConnectionStringBuilder
    {
        Host = configurationRoot["POSTGRES_HOST"],
        Port = int.Parse(configurationRoot["POSTGRES_PORT"]!),
        Database = $"{configurationRoot["DEPLOY_ENV"]}_web",
    };
    optionsBuilder.UseNpgsql(stringBuilder.ConnectionString,
        action => action.MigrationsAssembly("{ProjectName}.Common.DbMigrations"));
    base.OnConfiguring(optionsBuilder);
}
```

## Redis Caching

```csharp
builder.Services.AddStackExchangeRedisCache(x =>
{
    x.ConfigurationOptions = new ConfigurationOptions()
    {
        EndPoints = new EndPointCollection() { { "redis-host", 6379 } },
    };
    x.InstanceName = "{project-name}-" + builder.Configuration["DEPLOY_ENV"] + "-";
});
```

## Cache Usage in Managers

```csharp
public async Task<UserPricesDto> GetPricesAsync(GetPricesRequest request)
{
    var data = await cacheManager.GetDataAsync(
        Constants.CacheKeys.UserPriceLevels(request.UserId),
        () => repository.GetByUserId(request.UserId),
        TimeSpan.FromDays(1)
    );
    return data;
}
```

## Cache Key Constants

```csharp
public static class Constants
{
    public static class CacheKeys
    {
        public const string Products = "all-products-dict";
        public static string UserPriceLevels(long userId) => $"user-price-levels-{userId}";
    }
}
```
