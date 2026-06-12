# ── Stage 1: Build ─────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /app

# Copy only csproj first (for caching restore properly)
COPY MyApi/MyApi.csproj MyApi/
COPY MyApi.Tests/MyApi.Tests.csproj MyApi.Tests/

# Restore BOTH projects explicitly (no guessing, no cache issues)
RUN dotnet restore MyApi/MyApi.csproj
RUN dotnet restore MyApi.Tests/MyApi.Tests.csproj

# Copy full source
COPY . .

# Run tests (fail fast if broken)
RUN dotnet test MyApi.Tests/MyApi.Tests.csproj \
    -c Release \
    --no-restore \
    --logger "console;verbosity=normal"

# Publish API (DO NOT use --no-restore, avoids cache corruption issues)
RUN dotnet publish MyApi/MyApi.csproj \
    -c Release \
    -o /app/publish


# ── Stage 2: Runtime ───────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime

WORKDIR /app

# Create non-root user (safe across Debian-based images)
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Copy published output
COPY --from=build /app/publish .

# Fix permissions
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ENTRYPOINT ["dotnet", "MyApi.dll"]