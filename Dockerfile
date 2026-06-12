# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files first for layer caching
COPY MyApi/MyApi.csproj MyApi/
COPY MyApi.Tests/MyApi.Tests.csproj MyApi.Tests/

RUN dotnet restore MyApi/MyApi.csproj

# Copy source code
COPY MyApi/ MyApi/
COPY MyApi.Tests/ MyApi.Tests/

# Run tests
RUN dotnet test MyApi.Tests/MyApi.Tests.csproj \
    --configuration Release \
    --no-restore \
    --logger "console;verbosity=minimal"

# Publish application
RUN dotnet publish MyApi/MyApi.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime

WORKDIR /app

# Create non-root user
RUN groupadd -r appgroup && \
    useradd -r -g appgroup -d /app -s /sbin/nologin appuser

# Copy published application
COPY --from=build /app/publish .

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

ARG IMAGE_TAG=local
ENV IMAGE_TAG=$IMAGE_TAG

ENTRYPOINT ["dotnet", "MyApi.dll"]