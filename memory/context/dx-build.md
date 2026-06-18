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
