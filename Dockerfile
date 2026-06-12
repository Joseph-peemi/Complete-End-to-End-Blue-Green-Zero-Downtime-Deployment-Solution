# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build

WORKDIR /app

# Copy project files first (for caching)
COPY MyApi/MyApi.csproj MyApi/
COPY MyApi.Tests/MyApi.Tests.csproj MyApi.Tests/

# Restore explicitly (no guessing, no src, no sln required)
RUN dotnet restore MyApi/MyApi.csproj

# Copy full source
COPY . .

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

RUN groupadd -r appgroup && \
    useradd -r -g appgroup -d /app -s /usr/sbin/nologin appuser

COPY --from=build /app/publish .

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ARG IMAGE_TAG=local
ENV IMAGE_TAG=$IMAGE_TAG

ENTRYPOINT ["dotnet", "MyApi.dll"]