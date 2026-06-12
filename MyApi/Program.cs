using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using System.Text.Json;

var builder = WebApplication.CreateBuilder(args);

// ── Bind config from environment variables ──────────────────────────────────
// All secrets come from ECS task definition "secrets" block at runtime.
// Never read them from appsettings.json.
builder.Configuration.AddEnvironmentVariables();

// ── Services ────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// ── Health checks ────────────────────────────────────────────────────────────
// This /health endpoint is what the ALB polls every 30 seconds.
// Add checks for each downstream dependency your app needs.
builder.Services.AddHealthChecks()
    .AddCheck("self", () => 
        Microsoft.Extensions.Diagnostics.HealthChecks
            .HealthCheckResult.Healthy("API is running"))
    .AddCheck<DatabaseHealthCheck>("database");

var app = builder.Build();

// ── Middleware ───────────────────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Map health endpoint BEFORE auth middleware so ALB can always reach it
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = JsonSerializer.Serialize(new
        {
            status  = report.Status.ToString(),
            slot    = Environment.GetEnvironmentVariable("SLOT") ?? "unknown",
            version = Environment.GetEnvironmentVariable("IMAGE_TAG") ?? "unknown",
            checks  = report.Entries.Select(e => new
            {
                name    = e.Key,
                status  = e.Value.Status.ToString(),
                duration = e.Value.Duration.TotalMilliseconds
            })
        });
        await context.Response.WriteAsync(result);
    }
});

app.UseHttpsRedirection();
// app.UseAuthorization();
app.MapControllers();

app.Run();