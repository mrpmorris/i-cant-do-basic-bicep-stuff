using Azure.Identity;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MyApp.ServiceDefaults;
using OpenTelemetry.Logs;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using System.Reflection;

namespace MyApp.ServiceDefaults;

public static class Extensions
{
	public static T AddServiceDefaults<T>(
		this T builder,
		Assembly executingAssembly,
		bool useOtlpExporter,
		bool isDevelopment)
	where T : IHostBuilder
	{
		ArgumentNullException.ThrowIfNull(executingAssembly);

		builder.ConfigureHttpClientDefaults();
		builder.ConfigureServices(services =>
		{
			services.AddHttpClient();
		});

		builder.ConfigureOpenTelemetry(
			executingAssembly: executingAssembly,
			useOtlpExporter: useOtlpExporter,
			isDevelopment: isDevelopment);

		builder.AddDefaultHealthChecks();
		builder.AddServiceDiscovery();
		builder.ConfigureAppConfiguration((context, configBuilder) =>
		{
			string environmentName = context.HostingEnvironment.EnvironmentName;
			configBuilder.AddJsonFile("appsettings.json", optional: false);
			configBuilder.AddJsonFile($"appsettings.{environmentName}.json", optional: true);
			configBuilder.AddEnvironmentVariables();

			//if (!context.HostingEnvironment.IsDevelopment())
			//{
			//	string keyVaultName = context.Configuration.GetValue<string>("KeyVaultName")!;
			//	configBuilder.AddAzureKeyVault(
			//		new Uri($"https://{keyVaultName}.vault.azure.net/"),
			//		new DefaultAzureCredential()
			//	);
			//}
		});
		return builder;
	}

	private static T AddServiceDiscovery<T>(this T builder)
		where T : IHostBuilder
	{
		builder.ConfigureServices(services =>
		{
			services.AddServiceDiscovery();
		});
		return builder;
	}

	private static T ConfigureHttpClientDefaults<T>(this T builder)
		where T : IHostBuilder
	{
		builder.ConfigureServices(services =>
		{
			services.ConfigureHttpClientDefaults(http =>
			{
				// Turn on resilience by default
				http.AddStandardResilienceHandler();

				// Turn on service discovery by default
				http.UseServiceDiscovery();
			});
		});
		return builder;
	}

	private static T ConfigureOpenTelemetry<T>(
		this T builder,
		Assembly executingAssembly,
		bool useOtlpExporter,
		bool isDevelopment)
	where T : IHostBuilder
	{
		builder.ConfigureAppConfiguration((context, _) =>
		{
			//Environment.SetEnvironmentVariable("OTEL_SERVICE_NAME", $"MyApp-{context.HostingEnvironment.EnvironmentName}");
		});
		builder.ConfigureLogging(logging =>
		{
			logging.AddOpenTelemetry(telemetry =>
			{
				telemetry.IncludeFormattedMessage = true;
				telemetry.IncludeScopes = true;
			});
		});

		builder.ConfigureServices((context, services) =>
		{
			services.AddOpenTelemetry()
				.ConfigureResource(x =>
				{
					AssemblyName executingAssemblyName = executingAssembly.GetName();
					var hostingEnvironmentKvp = new KeyValuePair<string, object>(
						key: "environment.name",
						value: context.HostingEnvironment.EnvironmentName);
					x.AddAttributes([hostingEnvironmentKvp]);
					x.AddService(
						serviceName: executingAssemblyName.Name!,
						serviceNamespace: context.HostingEnvironment.EnvironmentName,
						serviceVersion: executingAssemblyName.Version!.ToString());
				})
				.WithMetrics(metrics =>
				{
					metrics
						.AddRuntimeInstrumentation()
						.AddBuiltInMeters();
				})
				.WithTracing(tracing =>

				{
					if (isDevelopment)
					{
						// We want to view all traces in development
						tracing.SetSampler(new AlwaysOnSampler());
					}

					tracing
						.AddSource("MyApp.*")
						.AddAspNetCoreInstrumentation()
						.AddGrpcClientInstrumentation()
						.AddHttpClientInstrumentation()
						//.AddOtlpExporter(otlpOptions =>
						//{
						//	otlpOptions.Endpoint = new Uri($"https://api.honeycomb.io:443");
						//	otlpOptions.Headers = string.Join(
						//		",",
						//	   new List<string>
						//		{
						//			"x-otlp-version=0.16.0",
						//			$"x-honeycomb-team=...."
						//		});
						//})
						;
					//.AddCommonInstrumentations();
				});
		});

		builder.AddOpenTelemetryExporters(useOtlpExporter);
		return builder;
	}

	private static T AddOpenTelemetryExporters<T>(this T builder, bool useOtlpExporter)
		where T : IHostBuilder
	{
		builder.ConfigureServices(services =>
		{
			if (useOtlpExporter)
			{
				services.Configure<OpenTelemetryLoggerOptions>(logging => logging.AddOtlpExporter());
				services.ConfigureOpenTelemetryMeterProvider(metrics => metrics.AddOtlpExporter());
				services.ConfigureOpenTelemetryTracerProvider(tracing => tracing.AddOtlpExporter());
			}
		});

		return builder;
	}

	public static T AddDefaultHealthChecks<T>(this T builder)
		where T : IHostBuilder
	{
		builder.ConfigureServices(services =>
		{
			services.AddHealthChecks()
				// Add a default liveness check to ensure app is responsive
				.AddCheck("self", () => HealthCheckResult.Healthy(), ["live"]);
		});
		return builder;
	}

	public static WebApplication MapDefaultHealthCheckEndpoints(this WebApplication app)
	{
		// Uncomment the following line to enable the Prometheus endpoint (requires the OpenTelemetry.Exporter.Prometheus.AspNetCore package)
		// app.MapPrometheusScrapingEndpoint();

		// All health checks must pass for app to be considered ready to accept traffic after starting
		app.MapHealthChecks("/health");

		// Only health checks tagged with the "live" tag must pass for app to be considered alive
		app.MapHealthChecks("/alive", new HealthCheckOptions
		{
			Predicate = r => r.Tags.Contains("live")
		});

		return app;
	}

	private static MeterProviderBuilder AddBuiltInMeters(this MeterProviderBuilder meterProviderBuilder) =>
		meterProviderBuilder.AddMeter(
			"Microsoft.AspNetCore.Hosting",
			"Microsoft.AspNetCore.Server.Kestrel",
			"System.Net.Http",
			"AzureFunctionsWorker");
}
