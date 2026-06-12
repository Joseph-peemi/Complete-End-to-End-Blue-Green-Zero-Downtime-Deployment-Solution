using Microsoft.Extensions.Diagnostics.HealthChecks;

public class DatabaseHealthCheck : IHealthCheck
{
    private readonly IConfiguration _config;

    public DatabaseHealthCheck(IConfiguration config)
    {
        _config = config;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Replace with your actual DB check — e.g. open a connection
            var connString = _config["ConnectionStrings__DefaultConnection"];
            
            if (string.IsNullOrEmpty(connString))
                return HealthCheckResult.Degraded("Connection string not found");

            // Simulate a DB ping — replace with real check
            await Task.Delay(10, cancellationToken);
            return HealthCheckResult.Healthy("Database reachable");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Database unreachable", ex);
        }
    }
}