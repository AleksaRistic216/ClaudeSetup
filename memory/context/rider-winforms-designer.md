---
name: rider-winforms-designer-missing
description: Fix for Rider not showing the WinForms designer in .NET SDK-style projects
metadata:
  type: feedback
---

When Rider doesn't show the WinForms designer for a form (no "Open in Designer" right-click option, no designer toggle in the editor), add explicit MSBuild metadata to the `.csproj`:

```xml
<ItemGroup>
  <Compile Update="MyForm.cs">
    <SubType>Form</SubType>
  </Compile>
  <Compile Update="MyForm.Designer.cs">
    <DependentUpon>MyForm.cs</DependentUpon>
  </Compile>
  <EmbeddedResource Update="MyForm.resx">
    <DependentUpon>MyForm.cs</DependentUpon>
  </EmbeddedResource>
</ItemGroup>
```

Then reload the project in Rider. The `SubType=Form` is what Rider uses to identify a file as a WinForms form vs. a plain class.

**Why:** SDK-style projects don't emit these entries automatically, so Rider can't distinguish a Form class from any other class inheriting from `Form`.

**How to apply:** Any time a .NET SDK-style WinForms project's form designer is missing in Rider, add this metadata block and reload. Applies to any project, not just this repo.
