# Project Bundle Creation Instructions

Use these instructions to create a new project bundle consisting of a backend (.NET) and frontend (Next.js) project.

## Overview

This guide creates a full-stack project bundle consisting of:
- **Backend (BE)**: .NET 9.0 layered architecture with API, Contracts, Domain, Repository, Client, DbMigrations, and Tests projects
- **Frontend (FE)**: Next.js 13+ with React 18, JavaScript (JSX), MUI, organized by widgets/features
- **Common Libraries**: Shared contracts, domain, and repository used across multiple modules

---

## Part 1: Backend (.NET) Project Structure

### 1.1 Project Naming Convention

Replace `{ProjectName}` with your actual project name (e.g., `CS.MyModule`).

```
src/{ProjectName}/
├── {ProjectName}.Common/                    # Shared across all modules
│   ├── {ProjectName}.Common.Contracts/      # Shared entities, DTOs, interfaces
│   ├── {ProjectName}.Common.Domain/         # Shared managers, validators
│   ├── {ProjectName}.Common.Repository/     # DbContext, shared repositories
│   └── {ProjectName}.Common.DbMigrations/   # EF Core migrations
├── {ProjectName}.Public/                    # Main API module
│   ├── {ProjectName}.{Application}.Api/            # Controllers, Program.cs
│   ├── {ProjectName}.{Application}.Contracts/      # Module-specific DTOs, interfaces
│   ├── {ProjectName}.{Application}.Domain/         # Business logic (Managers)
│   ├── {ProjectName}.{Application}.Repository/     # Module-specific repositories
│   ├── {ProjectName}.{Application}.Client/         # API client for inter-service calls
│   ├── {ProjectName}.{Application}.Tests/          # Unit/Integration .NET tests
│   ├── {ProjectName}.{Application}.Fe/             # Next.js frontend
```

### 1.2 Common.Contracts Project

**File: `{ProjectName}.Common.Contracts.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Contracts" Version="9.1.2" />
    <PackageReference Include="LSCore.Auth.UserPass.Contracts" Version="9.1.2" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Common.Contracts/
├── Attributes/              # Custom attributes
├── Constants/               # Shared constants
├── Dtos/                    # Shared DTOs
│   └── Vault/
│       └── SecretsDto.cs
├── Entities/                # Database entities
│   ├── UserEntity.cs
│   ├── SettingEntity.cs
│   └── LogEntity.cs
├── Enums/                   # Shared enumerations
├── Helpers/                 # Utility helpers
├── IManagers/               # Shared manager interfaces
├── IRepositories/           # Shared repository interfaces
│   ├── ILogRepository.cs
│   └── ISettingRepository.cs
├── Models/                  # Domain models
└── Requests/                # Shared request objects
```

**Sample Entity (`UserEntity.cs`):**
```csharp
using LSCore.Contracts;
using LSCore.Auth.UserPass.Contracts;

namespace {ProjectName}.Common.Contracts.Entities;

public class UserEntity : LSCoreEntity, ILSCoreAuthUserPassEntity<string>
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string? RefreshToken { get; set; }
    public string Nickname { get; set; } = string.Empty;

    // ILSCoreAuthUserPassEntity implementation
    public string Identifier => Username;
}
```

### 1.3 Common.Repository Project

**File: `{ProjectName}.Common.Repository.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Repository" Version="9.1.2" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="9.0.3" />
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="9.0.0" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Common.Contracts\{ProjectName}.Common.Contracts.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Common.Repository/
├── EntityMappings/
│   ├── UserEntityMap.cs
│   ├── SettingEntityMap.cs
│   └── LogEntityMap.cs
├── Repositories/
│   ├── LogRepository.cs
│   └── SettingRepository.cs
├── {ProjectName}DbContext.cs
└── ServicesExtensions.cs
```

**Sample DbContext (`{ProjectName}DbContext.cs`):**
```csharp
using LSCore.Repository;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using {ProjectName}.Common.Contracts.Entities;

namespace {ProjectName}.Common.Repository;

public class {ProjectName}DbContext(
    DbContextOptions<{ProjectName}DbContext> options,
    IConfigurationRoot configurationRoot
) : LSCoreDbContext<{ProjectName}DbContext>(options)
{
    public DbSet<UserEntity> Users { get; set; }
    public DbSet<SettingEntity> Settings { get; set; }
    public DbSet<LogEntity> Logs { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        var connectionString = DbConstants.ConnectionString(configurationRoot);
        optionsBuilder.UseNpgsql(connectionString);
        base.OnConfiguring(optionsBuilder);
    }
}
```

**Sample EntityMap (`UserEntityMap.cs`):**
```csharp
using LSCore.Repository;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using {ProjectName}.Common.Contracts.Entities;

namespace {ProjectName}.Common.Repository.EntityMappings;

public class UserEntityMap : LSCoreEntityMap<UserEntity>
{
    public override Action<EntityTypeBuilder<UserEntity>> Mapper { get; } =
        builder =>
        {
            builder.Property(x => x.Username).IsRequired().HasMaxLength(64);
            builder.Property(x => x.Password).IsRequired().HasMaxLength(64);
            builder.Property(x => x.Nickname).IsRequired().HasMaxLength(64);
        };
}
```

**Sample ServicesExtensions.cs:**
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace {ProjectName}.Common.Repository;

public static class ServicesExtensions
{
    public static void RegisterDatabase(this IServiceCollection serviceCollection)
    {
        serviceCollection
            .AddEntityFrameworkNpgsql()
            .AddDbContext<{ProjectName}DbContext>(
                (serviceProvider, options) =>
                {
                    options.UseInternalServiceProvider(serviceProvider);
                }
            );
    }
}
```

### 1.4 Common.Domain Project

**File: `{ProjectName}.Common.Domain.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Validation" Version="9.1.2" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Common.Contracts\{ProjectName}.Common.Contracts.csproj" />
    <ProjectReference Include="..\{ProjectName}.Common.Repository\{ProjectName}.Common.Repository.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Common.Domain/
├── Extensions/
├── Managers/
│   └── LogManager.cs
└── Validators/
```

### 1.5 Common.DbMigrations Project

**File: `{ProjectName}.Common.DbMigrations.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="9.0.0">
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
      <PrivateAssets>all</PrivateAssets>
    </PackageReference>
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="9.0.3" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Common.Repository\{ProjectName}.Common.Repository.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Common.DbMigrations/
├── Migrations/           # EF Core generated migrations
├── DbSeeds/
│   └── Down/
├── Program.cs
└── appsettings.json
```

**Sample Program.cs for Migrations:**
```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using {ProjectName}.Common.Repository;

var builder = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true);

var configuration = builder.Build();

var optionsBuilder = new DbContextOptionsBuilder<{ProjectName}DbContext>();
optionsBuilder.UseNpgsql(
    DbConstants.ConnectionString(configuration),
    x => x.MigrationsAssembly("{ProjectName}.Common.DbMigrations")
        .MigrationsHistoryTable("migrations_history")
);

using var context = new {ProjectName}DbContext(optionsBuilder.Options, configuration);
```

### 1.6 Public.Api Project

**File: `{ProjectName}.Public.Api.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <UserSecretsId>your-guid-here</UserSecretsId>
    <DockerDefaultTargetOS>Linux</DockerDefaultTargetOS>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Auth.Key.DependencyInjection" Version="9.1.4.1" />
    <PackageReference Include="LSCore.Auth.UserPass.DependencyInjection" Version="9.1.2" />
    <PackageReference Include="LSCore.Exceptions.DependencyInjection" Version="9.1.2" />
    <PackageReference Include="LSCore.Logging" Version="9.1.2" />
    <PackageReference Include="LSCore.DependencyInjection" Version="9.1.2" />
    <PackageReference Include="Microsoft.Extensions.Caching.StackExchangeRedis" Version="9.0.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Public.Domain\{ProjectName}.Public.Domain.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Public.Api/
├── Controllers/
│   ├── PingController.cs
│   └── UsersController.cs
├── Properties/
│   └── launchSettings.json
├── Program.cs
├── appsettings.json
├── appsettings.Development.json
└── Dockerfile
```

**Sample Program.cs:**
```csharp
using LSCore.Auth.Key.DependencyInjection;
using LSCore.Auth.UserPass.DependencyInjection;
using LSCore.DependencyInjection;
using LSCore.Exceptions.DependencyInjection;
using LSCore.Logging;
using {ProjectName}.Common.Repository;

var builder = WebApplication.CreateBuilder(args);

// Add configuration
builder.AddCommon();

// Add Redis caching (optional)
builder.Services.AddStackExchangeRedisCache(options =>
{
    options.InstanceName = "{project-name}-" + Environment.GetEnvironmentVariable("DEPLOY_ENV") + "-";
    options.ConfigurationOptions = new StackExchange.Redis.ConfigurationOptions
    {
        EndPoints = { { "your-redis-host", 6379 } },
        SyncTimeout = 30 * 1000
    };
});

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
    });
});

// Add Auth
builder.AddLSCoreAuthUserPass(new LSCoreAuthUserPassConfiguration
{
    AccessTokenExpirationMinutes = 720,
    RefreshTokenExpirationMinutes = 43200,
    Audience = "{project-name}-termodom",
    Issuer = "{project-name}-termodom",
    SecurityKey = Environment.GetEnvironmentVariable("JWT_KEY") ?? "your-dev-key"
});

// Register database
builder.Services.RegisterDatabase();

// Add LSCore DI (auto-registers managers, repositories, validators)
builder.AddLSCoreDependencyInjection("{ProjectName}");

// Add logging
builder.AddLSCoreLogging();

// Add controllers
builder.Services.AddControllers();

var app = builder.Build();

app.UseCors();
app.UseAuthentication();
app.UseAuthorization();
app.UseLSCoreExceptions();
app.MapControllers();

app.Run();
```

**Sample Controller (`UsersController.cs`):**
```csharp
using LSCore.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using {ProjectName}.Public.Contracts.Interfaces.IManagers;
using {ProjectName}.Public.Contracts.Requests.Users;

namespace {ProjectName}.Public.Api.Controllers;

[ApiController]
[Route("[controller]")]
[Authorize]
public class UsersController(IUserManager userManager) : ControllerBase
{
    [HttpGet]
    public IActionResult GetAll([FromQuery] LSCorePaginatedRequest request)
    {
        return Ok(userManager.GetAll(request));
    }

    [HttpGet("{id}")]
    public IActionResult GetSingle([FromRoute] LSCoreIdRequest request)
    {
        return Ok(userManager.GetSingle(request));
    }

    [HttpPut]
    public IActionResult CreateOrUpdate([FromBody] UsersCreateRequest request)
    {
        userManager.CreateOrUpdate(request);
        return Ok();
    }

    [HttpDelete("{id}")]
    public IActionResult Delete([FromRoute] LSCoreIdRequest request)
    {
        userManager.Delete(request);
        return Ok();
    }
}
```

### 1.7 Public.Contracts Project

**File: `{ProjectName}.Public.Contracts.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Auth.Key.Contracts" Version="9.1.3" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\{ProjectName}.Common\{ProjectName}.Common.Contracts\{ProjectName}.Common.Contracts.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Public.Contracts/
├── Constants/
├── Dtos/
│   └── Users/
│       └── UserDto.cs
├── DtosMappings/
│   └── UserDtoMapping.cs
├── Enums/
│   ├── SortColumnCodes/
│   └── ValidationCodes/
├── Helpers/
├── Interfaces/
│   ├── IManagers/
│   │   └── IUserManager.cs
│   ├── IRepositories/
│   │   └── IUserRepository.cs
│   ├── IApiClients/
│   └── Factories/
└── Requests/
    └── Users/
        └── UsersCreateRequest.cs
```

**Sample Interface (`IUserManager.cs`):**
```csharp
using LSCore.Contracts;
using {ProjectName}.Public.Contracts.Dtos.Users;
using {ProjectName}.Public.Contracts.Requests.Users;

namespace {ProjectName}.Public.Contracts.Interfaces.IManagers;

public interface IUserManager
{
    LSCorePaginatedResponse<UserDto> GetAll(LSCorePaginatedRequest request);
    UserDto GetSingle(LSCoreIdRequest request);
    void CreateOrUpdate(UsersCreateRequest request);
    void Delete(LSCoreIdRequest request);
}
```

**Sample Request (`UsersCreateRequest.cs`):**
```csharp
namespace {ProjectName}.Public.Contracts.Requests.Users;

public class UsersCreateRequest
{
    public long? Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Nickname { get; set; } = string.Empty;
}
```

### 1.8 Public.Domain Project

**File: `{ProjectName}.Public.Domain.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.Auth.Key.Contracts" Version="9.1.4.1" />
    <PackageReference Include="LSCore.Validation" Version="9.1.2" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\{ProjectName}.Common\{ProjectName}.Common.Domain\{ProjectName}.Common.Domain.csproj" />
    <ProjectReference Include="..\{ProjectName}.Public.Contracts\{ProjectName}.Public.Contracts.csproj" />
    <ProjectReference Include="..\{ProjectName}.Public.Repository\{ProjectName}.Public.Repository.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Public.Domain/
├── Managers/
│   └── UserManager.cs
├── Validators/
│   └── Users/
│       └── UsersCreateRequestValidator.cs
├── ApiClients/
└── Factories/
```

**Sample Manager (`UserManager.cs`):**
```csharp
using LSCore.Contracts;
using LSCore.Mapper;
using {ProjectName}.Common.Contracts.Entities;
using {ProjectName}.Public.Contracts.Dtos.Users;
using {ProjectName}.Public.Contracts.Interfaces.IManagers;
using {ProjectName}.Public.Contracts.Interfaces.IRepositories;
using {ProjectName}.Public.Contracts.Requests.Users;

namespace {ProjectName}.Public.Domain.Managers;

public class UserManager(IUserRepository userRepository) : IUserManager
{
    public LSCorePaginatedResponse<UserDto> GetAll(LSCorePaginatedRequest request)
    {
        return userRepository.GetPaginated<UserDto>(request);
    }

    public UserDto GetSingle(LSCoreIdRequest request)
    {
        return userRepository.Get(request.Id).ToMapped<UserEntity, UserDto>();
    }

    public void CreateOrUpdate(UsersCreateRequest request)
    {
        if (request.Id == null)
        {
            userRepository.Add(request.ToMapped<UsersCreateRequest, UserEntity>());
        }
        else
        {
            var entity = userRepository.Get(request.Id.Value);
            entity.UpdateMapped(request);
            userRepository.Update(entity);
        }
    }

    public void Delete(LSCoreIdRequest request)
    {
        userRepository.Delete(request.Id);
    }
}
```

**Sample Validator (`UsersCreateRequestValidator.cs`):**
```csharp
using FluentValidation;
using LSCore.Validation;
using {ProjectName}.Common.Repository;
using {ProjectName}.Public.Contracts.Requests.Users;

namespace {ProjectName}.Public.Domain.Validators.Users;

public class UsersCreateRequestValidator : LSCoreValidatorBase<UsersCreateRequest>
{
    public UsersCreateRequestValidator({ProjectName}DbContext dbContext)
    {
        RuleFor(x => x.Username)
            .NotEmpty().WithMessage("Username is required")
            .MinimumLength(3).WithMessage("Username must be at least 3 characters");

        RuleFor(x => x.Password)
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(6).WithMessage("Password must be at least 6 characters");

        RuleFor(x => x.Nickname)
            .NotEmpty().WithMessage("Nickname is required");
    }
}
```

### 1.9 Public.Repository Project

**File: `{ProjectName}.Public.Repository.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\{ProjectName}.Common\{ProjectName}.Common.Repository\{ProjectName}.Common.Repository.csproj" />
    <ProjectReference Include="..\{ProjectName}.Public.Contracts\{ProjectName}.Public.Contracts.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Public.Repository/
└── Repositories/
    └── UserRepository.cs
```

**Sample Repository (`UserRepository.cs`):**
```csharp
using LSCore.Auth.Contracts;
using LSCore.Auth.UserPass.Contracts;
using LSCore.Repository;
using {ProjectName}.Common.Contracts.Entities;
using {ProjectName}.Common.Repository;
using {ProjectName}.Public.Contracts.Interfaces.IRepositories;

namespace {ProjectName}.Public.Repository.Repositories;

public class UserRepository(
    {ProjectName}DbContext dbContext,
    LSCoreAuthContextEntity<string> contextEntity
) : LSCoreRepositoryBase<UserEntity>(dbContext),
    IUserRepository,
    ILSCoreAuthUserPassIdentityEntityRepository<string>
{
    public UserEntity GetCurrentUser()
    {
        return Get(x => x.Username == contextEntity.Identifier);
    }

    public ILSCoreAuthUserPassEntity<string>? GetOrDefault(string identifier)
    {
        return dbContext.Users.FirstOrDefault(x => x.Username == identifier);
    }

    public void SetRefreshToken(string entityIdentifier, string refreshToken)
    {
        var user = Get(x => x.Username == entityIdentifier);
        user.RefreshToken = refreshToken;
        Update(user);
    }
}
```

### 1.10 Public.Client Project

**File: `{ProjectName}.Public.Client.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="LSCore.ApiClient.Rest" Version="9.1.4.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Public.Contracts\{ProjectName}.Public.Contracts.csproj" />
  </ItemGroup>
</Project>
```

**Directory Structure:**
```
{ProjectName}.Public.Client/
├── {ProjectName}Client.cs
└── Endpoints/
    └── UsersEndpoints.cs
```

### 1.11 Public.Tests Project

**File: `{ProjectName}.Public.Tests.csproj`**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.0.2" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="FluentAssertions" Version="8.8.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="9.0.0" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{ProjectName}.Public\{ProjectName}.Public.Api\{ProjectName}.Public.Api.csproj" />
    <ProjectReference Include="..\{ProjectName}.Public\{ProjectName}.Public.Domain\{ProjectName}.Public.Domain.csproj" />
  </ItemGroup>
</Project>
```

---

## Part 2: Frontend (Next.js) Project Structure

### 2.1 Project Initialization

**Location:** `src/{ProjectName}/{ProjectName}.Public/{ProjectName}.Public.Fe/`

**Create with:**
```bash
npx create-next-app@13 {ProjectName}.Public.Fe --js --eslint --no-tailwind --no-src-dir --app
# Then restructure to use src/ directory as shown below
```

### 2.2 Directory Structure

```
{ProjectName}.Public.Fe/
├── src/
│   ├── apis/                    # Axios API client
│   │   └── mainApi.js
│   ├── app/                     # Next.js App Router (optional)
│   │   ├── global.css
│   │   └── layout.jsx
│   ├── constants/               # Application constants
│   │   ├── cookies/
│   │   │   └── cookiesConstants.js
│   │   ├── endpoints/
│   │   │   └── endpointsConstants.js
│   │   ├── navBar/
│   │   │   └── navBarConstants.js
│   │   └── permissions/
│   │       └── permissionsConstants.js
│   ├── data/                    # JSON configuration files
│   │   └── fieldsConfig.json
│   ├── dtos/                    # TypeScript interfaces (can be JS with JSDoc)
│   │   └── users/
│   │       └── IUserDto.js
│   ├── features/                # Redux slices
│   │   └── slices/
│   │       └── userSlice/
│   │           └── userSlice.js
│   ├── helpers/                 # Utility functions
│   │   ├── dateHelpers.js
│   │   ├── numberHelpers.js
│   │   └── permissionsHelpers.js
│   ├── hooks/                   # Custom React hooks
│   │   ├── useUserHook.js
│   │   ├── useQuery.js
│   │   └── usePermissionsHook.js
│   ├── pages/                   # Next.js Pages Router
│   │   ├── _app.jsx
│   │   ├── index.jsx
│   │   └── [feature]/
│   │       └── index.jsx
│   ├── subModules/              # Sub-module navigation
│   │   └── useFeatureSubModules.js
│   ├── widgets/                 # Reusable UI components
│   │   ├── index.js             # Widget exports
│   │   ├── Layout/
│   │   │   └── ui/
│   │   │       └── Layout.jsx
│   │   └── [FeatureName]/
│   │       ├── ui/
│   │       ├── styled/
│   │       ├── interfaces/
│   │       ├── validations/
│   │       └── constants.js
│   ├── zStore/                  # Zustand stores
│   │   ├── index.js
│   │   └── zStore.js
│   ├── store.js                 # Redux store configuration
│   └── themes.js                # MUI theme configuration
├── public/                      # Static assets
├── package.json
├── next.config.js
├── jsconfig.json
├── .eslintrc.json
└── jest.config.js
```

### 2.3 Configuration Files

**package.json:**
```json
{
  "name": "{project-name}-public-fe",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "test:ci": "jest --ci --coverage --maxWorkers=2"
  },
  "dependencies": {
    "next": "13.4.19",
    "react": "18.2.0",
    "react-dom": "18.2.0",
    "@mui/material": "^5.14.15",
    "@mui/x-data-grid": "^6.17.0",
    "@mui/x-date-pickers": "^6.18.1",
    "@emotion/react": "^11.11.1",
    "@emotion/styled": "^11.11.0",
    "@reduxjs/toolkit": "^1.9.7",
    "react-redux": "^8.1.3",
    "zustand": "^5.0.0-rc.2",
    "axios": "^1.7.2",
    "react-hook-form": "^7.54.0",
    "yup": "^1.5.0",
    "@hookform/resolvers": "^3.3.2",
    "dayjs": "^1.11.10",
    "qs": "^6.13.0",
    "react-toastify": "^9.1.3",
    "js-cookie": "^3.0.5"
  },
  "devDependencies": {
    "eslint": "^8.52.0",
    "eslint-config-next": "13.4.19",
    "jest": "^29.7.0",
    "@testing-library/react": "^14.0.0",
    "@testing-library/jest-dom": "^6.1.4",
    "jest-environment-jsdom": "^29.7.0"
  }
}
```

**jsconfig.json:**
```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "target": "ES6",
    "module": "ESNext",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "jsx": "preserve"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

**next.config.js:**
```javascript
/** @type {import('next').NextConfig} */
const deploymentEnvironment = process.env.DEPLOYMENT_ENVIRONMENT || 'develop'

const apiBaseUrls = {
  stage: 'https://api-{project-name}-stage.example.com',
  develop: 'http://localhost:5195',
  production: 'https://api-{project-name}-production.example.com'
}

const nextConfig = {
  reactStrictMode: true,
  publicRuntimeConfig: {
    apiBaseUrl: apiBaseUrls[deploymentEnvironment]
  },
  async redirects() {
    return [
      // Add redirects here
    ]
  }
}

module.exports = nextConfig
```

**.eslintrc.json:**
```json
{
  "extends": "next/core-web-vitals"
}
```

**jest.config.js:**
```javascript
const nextJest = require('next/jest')

const createJestConfig = nextJest({
  dir: './'
})

const customJestConfig = {
  testEnvironment: 'jsdom',
  setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  testMatch: [
    '**/__tests__/**/*.[jt]s?(x)',
    '**/?(*.)+(spec|test).[jt]s?(x)'
  ],
  collectCoverageFrom: [
    'src/**/*.{js,jsx}',
    '!src/**/*.d.ts',
    '!src/**/*.test.{js,jsx}',
    '!src/**/*.spec.{js,jsx}'
  ],
  testTimeout: 10000
}

module.exports = createJestConfig(customJestConfig)
```

**jest.setup.js:**
```javascript
import '@testing-library/jest-dom'
```

### 2.4 Core Files

**src/apis/mainApi.js:**
```javascript
import axios from 'axios'
import qs from 'qs'
import Cookies from 'js-cookie'
import { toast } from 'react-toastify'
import { COOKIES_CONSTANTS } from '@/constants/cookies/cookiesConstants'

const mainApi = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL,
  paramsSerializer: params => qs.stringify(params, { arrayFormat: 'repeat' })
})

mainApi.interceptors.request.use(config => {
  const token = Cookies.get(COOKIES_CONSTANTS.TOKEN.NAME)
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

mainApi.interceptors.response.use(
  response => response,
  error => {
    handleApiError(error)
    return Promise.reject(error)
  }
)

function handleApiError(error) {
  const status = error.response?.status
  switch (status) {
    case 401:
      toast.error('Unauthorized. Please login again.')
      break
    case 403:
      toast.error('Access denied.')
      break
    case 404:
      toast.error('Resource not found.')
      break
    case 500:
      toast.error('Server error. Please try again later.')
      break
    default:
      toast.error('An error occurred.')
  }
}

export default mainApi
```

**src/store.js:**
```javascript
import { configureStore } from '@reduxjs/toolkit'
import userReducer from '@/features/slices/userSlice/userSlice'

export const store = configureStore({
  reducer: {
    user: userReducer
  }
})

// Custom hooks for typed dispatch/selector (optional for JS)
export const useAppDispatch = () => store.dispatch
export const useAppSelector = selector => selector(store.getState())
```

**src/features/slices/userSlice/userSlice.js:**
```javascript
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit'
import mainApi from '@/apis/mainApi'
import { ENDPOINTS_CONSTANTS } from '@/constants/endpoints/endpointsConstants'

export const fetchMe = createAsyncThunk('user/fetchMe', async () => {
  const response = await mainApi.get(ENDPOINTS_CONSTANTS.ME)
  return response.data
})

const initialState = {
  isLoading: false,
  isLogged: null,
  data: null
}

const userSlice = createSlice({
  name: 'user',
  initialState,
  reducers: {
    logout: state => {
      state.isLogged = false
      state.data = null
    }
  },
  extraReducers: builder => {
    builder
      .addCase(fetchMe.pending, state => {
        state.isLoading = true
      })
      .addCase(fetchMe.fulfilled, (state, action) => {
        state.isLoading = false
        state.isLogged = true
        state.data = action.payload
      })
      .addCase(fetchMe.rejected, state => {
        state.isLoading = false
        state.isLogged = false
        state.data = null
      })
  }
})

export const { logout } = userSlice.actions
export const selectUser = state => state.user
export default userSlice.reducer
```

**src/zStore/zStore.js:**
```javascript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

const STANDARD_REFRESH_INTERVAL = 10 * 60 * 1000 // 10 minutes
const LONG_REFRESH_INTERVAL = 24 * 60 * 60 * 1000 // 24 hours

export const useMainStore = create(
  persist(
    (set, get) => ({
      // UI state
      leftMenuVisible: true,
      toggleLeftMenu: () => set(state => ({ leftMenuVisible: !state.leftMenuVisible })),

      // Cached data example
      cachedData: null,
      lastRefresh: null,

      reloadAsync: async (forceReload = false) => {
        const now = Date.now()
        const lastRefresh = get().lastRefresh

        if (!forceReload && lastRefresh && now - lastRefresh < STANDARD_REFRESH_INTERVAL) {
          return get().cachedData
        }

        // Fetch and cache data
        // const response = await mainApi.get('/endpoint')
        // set({ cachedData: response.data, lastRefresh: now })
      }
    }),
    {
      name: '{project-name}-storage',
      partialize: state => ({
        leftMenuVisible: state.leftMenuVisible
      })
    }
  )
)
```

**src/zStore/index.js:**
```javascript
export { useMainStore } from './zStore'
// Export additional stores as needed
```

**src/hooks/useUserHook.js:**
```javascript
import { useEffect } from 'react'
import { useDispatch, useSelector } from 'react-redux'
import { useRouter } from 'next/router'
import { fetchMe, selectUser } from '@/features/slices/userSlice/userSlice'

export function useUser(redirectIfNotLogged = false, reload = false) {
  const dispatch = useDispatch()
  const router = useRouter()
  const user = useSelector(selectUser)

  useEffect(() => {
    if (user.isLogged === null || reload) {
      dispatch(fetchMe())
    }
  }, [dispatch, reload, user.isLogged])

  useEffect(() => {
    if (redirectIfNotLogged && user.isLogged === false) {
      router.push('/login')
    }
  }, [redirectIfNotLogged, user.isLogged, router])

  return user
}
```

**src/themes.js:**
```javascript
import { createTheme } from '@mui/material/styles'

const theme = createTheme({
  palette: {
    primary: {
      main: '#ff5b5b' // Your primary color
    },
    secondary: {
      main: '#007bff'
    }
  },
  typography: {
    fontFamily: [
      '-apple-system',
      'BlinkMacSystemFont',
      '"Segoe UI"',
      'Roboto',
      '"Helvetica Neue"',
      'Arial',
      'sans-serif'
    ].join(',')
  },
  // Custom theme extensions
  dataBackground: {
    light: '#f5f5f5',
    dark: '#e0e0e0'
  },
  defaultPagination: {
    pageSize: 25,
    pageSizeOptions: [10, 25, 50, 100]
  }
})

export default theme
```

**src/pages/_app.jsx:**
```javascript
import { Provider } from 'react-redux'
import { ThemeProvider } from '@mui/material/styles'
import CssBaseline from '@mui/material/CssBaseline'
import { LocalizationProvider } from '@mui/x-date-pickers'
import { AdapterDayjs } from '@mui/x-date-pickers/AdapterDayjs'
import { ToastContainer } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

import { store } from '@/store'
import theme from '@/themes'
import { Layout } from '@/widgets'

import '@/app/global.css'

export default function App({ Component, pageProps }) {
  return (
    <Provider store={store}>
      <LocalizationProvider dateAdapter={AdapterDayjs}>
        <ThemeProvider theme={theme}>
          <CssBaseline />
          <Layout>
            <Component {...pageProps} />
          </Layout>
          <ToastContainer
            position="bottom-right"
            autoClose={5000}
            hideProgressBar={false}
            closeOnClick
            pauseOnHover
          />
        </ThemeProvider>
      </LocalizationProvider>
    </Provider>
  )
}
```

**src/pages/index.jsx:**
```javascript
import { CircularProgress } from '@mui/material'
import { useUser } from '@/hooks/useUserHook'
import { Dashboard } from '@/widgets'

export default function HomePage() {
  const user = useUser(true)

  if (user.isLogged === null) {
    return <CircularProgress />
  }

  return <Dashboard />
}
```

**src/widgets/index.js:**
```javascript
// Layout widgets
export { Layout } from './Layout/ui/Layout'

// Feature widgets
export { Dashboard } from './Dashboard/ui/Dashboard'

// Common widgets
export { ConfirmDialog } from './ConfirmDialog/ui/ConfirmDialog'
export { TopActionBar } from './TopActionBar/ui/TopActionBar'

// Add more widget exports as needed
```

**src/widgets/Layout/ui/Layout.jsx:**
```javascript
import { Box, AppBar, Toolbar, Typography, Drawer, List, ListItem } from '@mui/material'
import { useMainStore } from '@/zStore'

const DRAWER_WIDTH = 240

export function Layout({ children }) {
  const { leftMenuVisible } = useMainStore()

  return (
    <Box sx={{ display: 'flex' }}>
      <AppBar position="fixed" sx={{ zIndex: theme => theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" noWrap component="div">
            {'{ProjectName}'}
          </Typography>
        </Toolbar>
      </AppBar>

      {leftMenuVisible && (
        <Drawer
          variant="permanent"
          sx={{
            width: DRAWER_WIDTH,
            flexShrink: 0,
            '& .MuiDrawer-paper': {
              width: DRAWER_WIDTH,
              boxSizing: 'border-box'
            }
          }}
        >
          <Toolbar />
          <Box sx={{ overflow: 'auto' }}>
            <List>
              {/* Navigation items */}
            </List>
          </Box>
        </Drawer>
      )}

      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar />
        {children}
      </Box>
    </Box>
  )
}
```

**src/constants/cookies/cookiesConstants.js:**
```javascript
export const COOKIES_CONSTANTS = {
  TOKEN: {
    NAME: '{project_name}_token',
    EXPIRES: 30 // days
  },
  REFRESH_TOKEN: {
    NAME: '{project_name}_refresh_token',
    EXPIRES: 30
  }
}
```

**src/constants/endpoints/endpointsConstants.js:**
```javascript
export const ENDPOINTS_CONSTANTS = {
  // Auth
  LOGIN: '/auth/login',
  LOGOUT: '/auth/logout',
  ME: '/auth/me',
  REFRESH: '/auth/refresh',

  // Users
  USERS: '/users',

  // Add more endpoints as needed
}
```

**src/app/global.css:**
```css
:root {
  --primary-color: #ff5b5b;
  --secondary-color: #007bff;
  --background-light: #f5f5f5;
  --background-dark: #e0e0e0;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html,
body {
  max-width: 100vw;
  overflow-x: hidden;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

a {
  color: inherit;
  text-decoration: none;
}
```

---

## Part 3: Widget Structure Pattern

Each widget follows this structure:

```
WidgetName/
├── ui/                      # UI components
│   ├── WidgetName.jsx       # Main component
│   └── WidgetNameItem.jsx   # Sub-components
├── styled/                  # Styled components (optional)
│   └── StyledWidgetName.js
├── interfaces/              # TypeScript interfaces (or JSDoc types)
│   └── IWidgetNameProps.js
├── validations/             # Yup validation schemas
│   └── widgetNameSchema.js
├── constants.js             # Widget-specific constants
└── index.js                 # Exports
```

**Example Widget (UserList):**

**src/widgets/UserList/ui/UserList.jsx:**
```javascript
import { useState, useEffect } from 'react'
import { DataGrid } from '@mui/x-data-grid'
import { Box, Button } from '@mui/material'
import mainApi from '@/apis/mainApi'
import { ENDPOINTS_CONSTANTS } from '@/constants/endpoints/endpointsConstants'
import { USER_LIST_COLUMNS } from '../constants'

export function UserList() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [paginationModel, setPaginationModel] = useState({
    page: 0,
    pageSize: 25
  })

  useEffect(() => {
    fetchUsers()
  }, [paginationModel])

  const fetchUsers = async () => {
    setLoading(true)
    try {
      const response = await mainApi.get(ENDPOINTS_CONSTANTS.USERS, {
        params: {
          page: paginationModel.page + 1,
          pageSize: paginationModel.pageSize
        }
      })
      setUsers(response.data.items)
    } finally {
      setLoading(false)
    }
  }

  return (
    <Box sx={{ height: 600, width: '100%' }}>
      <DataGrid
        rows={users}
        columns={USER_LIST_COLUMNS}
        loading={loading}
        paginationModel={paginationModel}
        onPaginationModelChange={setPaginationModel}
        pageSizeOptions={[10, 25, 50, 100]}
      />
    </Box>
  )
}
```

**src/widgets/UserList/constants.js:**
```javascript
export const USER_LIST_COLUMNS = [
  { field: 'id', headerName: 'ID', width: 70 },
  { field: 'username', headerName: 'Username', width: 150 },
  { field: 'nickname', headerName: 'Nickname', width: 150 },
  { field: 'createdAt', headerName: 'Created', width: 180 }
]
```

**src/widgets/UserList/validations/userSchema.js:**
```javascript
import * as yup from 'yup'

export const userSchema = yup.object({
  username: yup
    .string()
    .required('Username is required')
    .min(3, 'Username must be at least 3 characters'),
  password: yup
    .string()
    .required('Password is required')
    .min(6, 'Password must be at least 6 characters'),
  nickname: yup
    .string()
    .required('Nickname is required')
})
```

---

## Part 4: Key Architectural Rules

### Backend Rules

1. **Always update interfaces when modifying implementations**
   - Interface: `Contracts/Interfaces/IManagers/IUserManager.cs`
   - Implementation: `Domain/Managers/UserManager.cs`

2. **REST API routing conventions**
   - Resource IDs in URL path: `PUT /users/{id}/status`
   - Create/Update shared endpoint: `PUT /users` with nullable `Id` in request

3. **Entity configuration**
   - Default values: `builder.Property(x => x.Status).HasDefaultValueSql("0");`
   - Create migration after entity changes

4. **Layer dependencies**
   - Api → Domain → Repository → Common.Repository
   - Contracts can be referenced by any layer

### Frontend Rules

1. **State management split**
   - Redux: Global user/auth state
   - Zustand: Feature-specific cached data with refresh intervals

2. **Widget organization**
   - Each widget is self-contained with ui/, styled/, validations/
   - Export all widgets from `widgets/index.js`

3. **API communication**
   - Single Axios instance in `apis/mainApi.js`
   - Endpoints defined in constants
   - Error handling via interceptors

4. **Forms**
   - React Hook Form + Yup
   - Schemas in widget's `validations/` folder

---

## Part 5: Commands Reference

### Backend

```bash
# Restore dependencies
dotnet restore src/{ProjectName}/{ProjectName}.Public/{ProjectName}.Public.Api/{ProjectName}.Public.Api.csproj

# Build project
dotnet build src/{ProjectName}/{ProjectName}.Public/{ProjectName}.Public.Api/{ProjectName}.Public.Api.csproj

# Run project
dotnet run --project src/{ProjectName}/{ProjectName}.Public/{ProjectName}.Public.Api/{ProjectName}.Public.Api.csproj

# Add migration
dotnet ef migrations add MigrationName --project src/{ProjectName}/{ProjectName}.Common/{ProjectName}.Common.DbMigrations

# Run tests
dotnet test src/{ProjectName}/{ProjectName}.Public.Tests/{ProjectName}.Public.Tests.csproj
```

### Frontend

```bash
# Install dependencies
cd src/{ProjectName}/{ProjectName}.Public/{ProjectName}.Public.Fe
npm install

# Development
npm run dev

# Build
npm run build

# Test
npm test
npm run test:coverage
```

---

## Part 6: Checklist for New Project

### Backend Checklist
- [ ] Create solution file (.sln)
- [ ] Create Common.Contracts project with entities
- [ ] Create Common.Repository project with DbContext
- [ ] Create Common.Domain project
- [ ] Create Common.DbMigrations project
- [ ] Create Public.Api project with Program.cs
- [ ] Create Public.Contracts project with DTOs and interfaces
- [ ] Create Public.Domain project with managers and validators
- [ ] Create Public.Repository project with repositories
- [ ] Create Public.Client project
- [ ] Create Public.Tests project
- [ ] Add initial migration
- [ ] Configure appsettings.json with Vault/environment settings

### Frontend Checklist
- [ ] Initialize Next.js project
- [ ] Configure jsconfig.json with path aliases
- [ ] Configure next.config.js with environment URLs
- [ ] Set up Redux store
- [ ] Set up Zustand stores
- [ ] Create main API client
- [ ] Set up _app.jsx with providers
- [ ] Create Layout widget
- [ ] Configure constants (cookies, endpoints, permissions)
- [ ] Set up theme
- [ ] Configure Jest for testing
