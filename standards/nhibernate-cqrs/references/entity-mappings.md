# Entity Mappings

Entities are mapped with NHibernate **XML mappings (`.hbm.xml`)** — not Fluent NHibernate, not attributes.

## The three rules

### 1. Sibling placement

The `.hbm.xml` lives in the same folder as the `.cs` file it maps, with a matching file name.

```
DomainModel/Security/
├── PortalUser.cs
├── PortalUser.hbm.xml      ← sibling mapping
├── PortalSession.cs
└── PortalSession.hbm.xml
```

### 2. Embedded resource

Each `.hbm.xml` is registered as `<EmbeddedResource>` in the DomainModel `.csproj`. The session factory loads mappings from the assembly at startup — files that aren't embedded are silently ignored.

```xml
<ItemGroup>
  <EmbeddedResource Include="Security\PortalUser.hbm.xml" />
  <EmbeddedResource Include="Security\PortalSession.hbm.xml" />
  <EmbeddedResource Include="Documents\DocumentArchive.hbm.xml" />
  <!-- one line per entity -->
</ItemGroup>
```

### 3. Mapping header matches the folder namespace

The `assembly` and `namespace` attributes on `<hibernate-mapping>` must match the DomainModel assembly and the entity's C# namespace.

```xml
<?xml version="1.0" encoding="utf-8" ?>
<hibernate-mapping xmlns="urn:nhibernate-mapping-2.2"
                   assembly="Holo.{Project}.DomainModel"
                   namespace="Holo.{Project}.DomainModel.Security">

  <class name="PortalUser" table="sec_portal_user">
    <id name="Id" column="id">
      <generator class="identity"/>
    </id>
    <property name="UniqueCode" column="unique_code" />
    <property name="Username"   column="username" />
    <many-to-one name="Role"    column="role_id" />
    <property name="IsActive"   column="is_active" />
    <property name="CreatedAt"  column="created_at" />
    <property name="ModifiedAt" column="modified_at" />
  </class>

</hibernate-mapping>
```

## Checklist when adding a new entity

1. Create `DomainModel/<Folder>/<Entity>.cs` with the POCO (public properties, `virtual` if lazy loading is needed).
2. Create `DomainModel/<Folder>/<Entity>.hbm.xml` next to it.
3. Set `assembly` and `namespace` on `<hibernate-mapping>` to match the entity's namespace.
4. Add `<EmbeddedResource Include="<Folder>\<Entity>.hbm.xml" />` to the DomainModel `.csproj`.
5. Build once and verify the entity is reachable via `Session.QueryOver<Entity>()` — a missing embed shows up as `MappingException: No persister for ...` at first query.

## Anti-patterns

- **Do not put mappings in a separate `Mappings/` folder.** Co-locating them with the entity keeps the two files in lock-step during renames and refactors.
- **Do not use Fluent NHibernate or mapping-by-code.** This project is XML-only for consistency.
- **Do not forget the `<EmbeddedResource>` entry.** The build will succeed, tests that don't hit the table will pass, and the first real query will throw at runtime.
