# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy csproj files first — Docker layer caches restored packages
# between builds unless .csproj files change
COPY MyApi/MyApi.csproj           MyApi/
COPY MyApi.Tests/MyApi.Tests.csproj MyApi.Tests/

RUN dotnet restore MyApi/MyApi.csproj

# Copy all source after restore — changes here don't re-trigger restore
COPY MyApi/       MyApi/
COPY MyApi.Tests/ MyApi.Tests/

# Run tests during build — pipeline fails if tests fail
RUN dotnet test MyApi.Tests/MyApi.Tests.csproj \
    --configuration Release \
    --no-restore \
    --logger "console;verbosity=minimal"

# Publish the API
RUN dotnet publish MyApi/MyApi.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Create non-root user — never run containers as root
RUN addgroup --system appgroup && \
    adduser  --system --ingroup appgroup appuser

# Copy published output from build stage only — no SDK, no source
COPY --from=build /app/publish .

# Set ownership
RUN chown -R appuser:appgroup /app

USER appuser

# Port 8080 matches ALB target group and ECS task definition
EXPOSE 8080

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# IMAGE_TAG is injected at build time by the pipeline
ARG IMAGE_TAG=local
ENV IMAGE_TAG=${IMAGE_TAG}

ENTRYPOINT ["dotnet", "MyApi.dll"]