# Testing

## Project Setup

Tests project references Api and Domain projects. Uses xUnit, Moq, FluentAssertions, and EF Core InMemory.

```xml
<ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.12.0" />
    <PackageReference Include="xunit" Version="2.9.3" />
    <PackageReference Include="xunit.runner.visualstudio" Version="3.0.2" />
    <PackageReference Include="Moq" Version="4.20.72" />
    <PackageReference Include="FluentAssertions" Version="8.8.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.InMemory" Version="9.0.0" />
    <PackageReference Include="FluentValidation.DependencyInjectionExtensions" Version="12.1.1" />
</ItemGroup>
```

## Test Base Class

```csharp
public abstract class TestBase
{
    protected readonly {ProjectName}DbContext _dbContext;
    private static readonly object Lock = new();

    protected TestBase()
    {
        var builder = Host.CreateApplicationBuilder();

        var options = new DbContextOptionsBuilder<{ProjectName}DbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        var configurationMock = new Mock<IConfigurationRoot>();
        var dbContext = new Test{ProjectName}DbContext(options, configurationMock.Object);

        lock (Lock)
        {
            builder.AddLSCoreDependencyInjection("{ProjectName}");
            var host = builder.Build();
            host.UseLSCoreDependencyInjection();
        }

        _dbContext = dbContext;
    }
}
```

## Test Pattern

```csharp
public class ProductManagerTests : TestBase
{
    private readonly IProductManager _manager;

    public ProductManagerTests()
    {
        var repository = new ProductRepository(_dbContext);
        _manager = new ProductManager(repository, Mock.Of<ILogger<ProductManager>>());
    }

    [Fact]
    public void Save_ValidRequest_ReturnsEntityId()
    {
        // Arrange
        var request = new ProductsSaveRequest
        {
            Name = "Test Product",
            Price = 100
        };

        // Act
        var result = _manager.Save(request);

        // Assert
        result.Should().BeGreaterThan(0);
    }

    [Fact]
    public void GetSingle_NonExistent_ThrowsNotFoundException()
    {
        // Arrange
        var request = new LSCoreIdRequest { Id = 999 };

        // Act
        var act = () => _manager.GetSingle(request);

        // Assert
        act.Should().Throw<LSCoreNotFoundException>();
    }
}
```

## Running Tests

```bash
dotnet test src/{ProjectName}/{ProjectName}.Public.Tests/{ProjectName}.Public.Tests.csproj
```
