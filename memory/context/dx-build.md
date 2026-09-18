# Building DevExpress Sources (dxvcs monorepo)

## MSBuild Location

Visual Studio 2025 (v18) is installed at:
```
C:\Program Files\Microsoft Visual Studio\18\Professional
```

MSBuild path:
```
C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe
```

## How to Build

### .NET Framework solutions (most Win/ projects)
Use MSBuild directly — `dotnet build` often fails on FW projects with resource errors.

```powershell
& "C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe" "path\to\Solution.sln" /t:Build /p:Configuration=Debug /v:q /nologo
```

### .NET (Core/Desktop) solutions
Use `dotnet build` with `--no-restore` (packages are pre-restored in this repo):

```powershell
dotnet build "path\to\Solution.NetCore.Desktop.sln" --no-restore -v q
```

## Common Pitfalls

- Do NOT use `dotnet build` on non-NetCore `.sln` files — they fail with MSB3823 resource errors.
- Always use `--no-restore` for dotnet builds (dependencies are managed centrally).
- The `.sln` file naming convention: `*.NetCore.Desktop.sln` = .NET, plain `*.sln` = .NET Framework.

## Solution Locations (common)

| Component | FW Solution | NetCore Solution |
|-----------|------------|-----------------|
| DevExpress.Utils | `Win/DevExpress.Utils/DevExpress.Utils/DevExpress.Utils.sln` | `Win/DevExpress.Utils/DevExpress.Utils/DevExpress.Utils.NetCore.Desktop.sln` |
| DevExpress.XtraBars | `Win/DevExpress.XtraBars/DevExpress.XtraBars/DevExpress.XtraBars.sln` | `Win/DevExpress.XtraBars/DevExpress.XtraBars/DevExpress.XtraBars.NetCore.Desktop.sln` |
| XtraBars Tests | `Win/DevExpress.XtraBars/DevExpress.XtraBars.Tests/DevExpress.XtraBars.Tests.sln` | `Win/DevExpress.XtraBars/DevExpress.XtraBars.Tests/DevExpress.XtraBars.Tests.NetCore.Desktop.sln` |

## How to Run Tests

Tests must be run using the NetCore.Desktop project (it has `Microsoft.NET.Test.Sdk`). The FW project does not.

### Step 1 — Build dependencies first (if sources changed)

```powershell
& "C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe" "Win/DevExpress.Utils/DevExpress.Utils/DevExpress.Utils.NetCore.Desktop.sln" /t:Build /p:Configuration=Debug /v:q /nologo
```

### Step 2 — Build the test project

```powershell
& "C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe" "Win/DevExpress.XtraBars/DevExpress.XtraBars.Tests/DevExpress.XtraBars.Tests.NetCore.Desktop.csproj" /t:Build /p:Configuration=Debug /v:q /nologo
```

### Step 3 — Run tests via vstest

```powershell
# All tests
dotnet vstest "Bin/NETCore/DevExpress.XtraBars.Tests.dll" --logger:"console;verbosity=normal"

# Filtered (e.g. by class or method name)
dotnet vstest "Bin/NETCore/DevExpress.XtraBars.Tests.dll" --TestCaseFilter:"FullyQualifiedName~DockManagerTests" --logger:"console;verbosity=normal"
```

### Notes
- `dotnet test` silently succeeds on the FW `.csproj` without running anything (no Test SDK).
- `dotnet test` on the NetCore `.csproj` fails with MSB4803 (COM reference needs full MSBuild).
- Always rebuild the dependency DLLs in `Bin/NETCore/` if the source assembly changed.
