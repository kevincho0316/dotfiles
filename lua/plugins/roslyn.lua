return {
  "seblj/roslyn.nvim",
  opts = {
    config = {
      -- Setting this to true allows the server to find your .sln file automatically
      choose_target = true,
      settings = {
      ["csharp|background_analysis"] = {
        dotnet_compiler_diagnostics_scope = "openFiles",
        dotnet_analyzer_diagnostics_scope = "openFiles",
      },
    },
    },
  }
}
