# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution structure
COPY MyApi/MyApi.csproj MyApi/
COPY MyApi.Tests/MyApi.Tests.csproj MyApi.Tests/

# Restore EVERYTHING (not just API project)
RUN dotnet restore

# Copy full source
COPY MyApi/ MyApi/
COPY MyApi.Tests/ MyApi.Tests/

# Run tests
RUN dotnet test MyApi.Tests/MyApi.Tests.csproj \
    -c Release \
    --no-restore \
    --logger "console;verbosity=minimal"

# Publish API
RUN dotnet publish MyApi/MyApi.csproj \
    -c Release \
    --no-restore \
    -o /app/publish

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Create non-root user (works on Debian-based images)
RUN groupadd -r appgroup && \
    useradd -r -g appgroup -d /app -s /usr/sbin/nologin appuser

# Copy published output
COPY --from=build /app/publish .

# Permissions
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ARG IMAGE_TAG=local
ENV IMAGE_TAG=$IMAGE_TAG

ENTRYPOINT ["dotnet", "MyApi.dll"]