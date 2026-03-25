# Architecture

## Layered Project Structure

Each domain follows a layered architecture with Common (shared) and Application-specific modules.

```
src/{ProjectName}/
├── {ProjectName}.Common/
│   ├── {ProjectName}.Common.Contracts/      # Shared entities, DTOs, interfaces, enums
│   ├── {ProjectName}.Common.Domain/         # Shared managers, validators
│   ├── {ProjectName}.Common.Repository/     # DbContext, shared repositories
│   └── {ProjectName}.Common.DbMigrations/   # EF Core migrations
├── {ProjectName}.Public/                    # Public-facing API module
│   ├── {ProjectName}.Public.Api/            # Controllers, Program.cs
│   ├── {ProjectName}.Public.Contracts/      # Module-specific DTOs, interfaces
│   ├── {ProjectName}.Public.Domain/         # Business logic (Managers, Validators)
│   ├── {ProjectName}.Public.Repository/     # Module-specific repositories
│   ├── {ProjectName}.Public.Client/         # API client for inter-service calls
│   ├── {ProjectName}.Public.Tests/          # Unit/Integration tests
│   └── {ProjectName}.Public.Fe/             # Next.js frontend
```

## Layer Dependencies

```
Api → Domain → Repository → Common.Repository
          ↓
      Contracts (referenced by any layer)
```

- **Api** depends on Domain
- **Domain** depends on Repository, Contracts, Common.Domain
- **Repository** depends on Common.Repository, Contracts
- **Contracts** can be referenced by any layer (no upward dependencies)

## Dependency Injection

LSCore auto-registers managers, repositories, validators, and mappers by convention:

```csharp
builder.AddLSCoreDependencyInjection("{ProjectName}");
```

This scans assemblies matching the prefix and registers:
- All `*Manager` classes to their `I*Manager` interfaces
- All `*Repository` classes to their `I*Repository` interfaces
- All `*Validator` classes
- All `*Mapper` classes

## Program.cs Setup Order

```csharp
var builder = WebApplication.CreateBuilder(args);

// 1. Configuration
builder.AddCommon();  // or manual config loading

// 2. Caching (optional)
builder.Services.AddStackExchangeRedisCache(...);

// 3. CORS
builder.Services.AddCors(...);

// 4. Authentication
builder.AddLSCoreAuthUserPass(...);

// 5. Database
builder.Services.RegisterDatabase();

// 6. LSCore DI (auto-registers managers, repos, validators)
builder.AddLSCoreDependencyInjection("{ProjectName}");

// 7. Logging
builder.AddLSCoreLogging();

// 8. Controllers
builder.Services.AddControllers();

var app = builder.Build();

// Middleware
app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.UseLSCoreExceptions();
app.MapControllers();

app.Run();
```
