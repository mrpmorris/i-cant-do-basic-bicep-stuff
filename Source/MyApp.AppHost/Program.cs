var builder = DistributedApplication.CreateBuilder(args);

builder.AddProject<Projects.TelegramSystem_Functions>("telegramsystem-functions");

builder.Build().Run();
