$taskRepoRoot = $PSScriptRoot
$taskSeeds = @(
  'frontend/test/tool/check_dependencies_test.dart',
  'frontend/test/tool/check_naming_test.dart',
  'frontend/test/tool/check_plan_test.dart',
  'frontend/test/tool/check_logging_test.dart',
  'frontend/test/tool/check_secrets_test.dart',
  'frontend/test/tool/check_tests_test.dart',
  'frontend/test/tool/check_templates_test.dart',
  'frontend/test/tool/new_task_test.dart',
  'frontend/test/tool/build_template_catalogue_test.dart',
  'frontend/test/tool/check_native_library_test.dart',
  'frontend/test/tool/whisper_vendor_test.dart',
  'frontend/test/tool/whisper_wasm_test.dart',
  'frontend/test/tool/support/plan_fixture.dart',
  'frontend/test/tool/sync_dev_tracker_test.dart',
  'frontend/test/core/import/pdf_pages_renderer_test.dart',
  'frontend/test/features/processing/data/notifications_test.dart',
  'frontend/test/core/security/authenticated_file_cipher_test.dart',
  'frontend/test/core/export/xlsx_encoder_test.dart',
  'frontend/test/core/bundle/bundle_zip_io_test.dart',
  'frontend/test/tool/check_l10n_test.dart',
  'frontend/test/tool/generated_source_check_test.dart',
  'frontend/test/tool/localization_generation_test.dart',
  'frontend/test/states/screen_inventory_test.dart',
  'frontend/test/architecture/data_safety_test.dart',
  'frontend/test/support/screen_inventory.dart',
  'frontend/test/architecture/support/owned_file_cleanup.dart',
  'frontend/test/architecture/support/owned_resource_flow.dart'
)
$taskSeeds += @(Get-Content -LiteralPath (Join-Path $taskRepoRoot 'frontend/build/task147/migration-files.txt') | Where-Object { $_ -match '^frontend/test/.+\.dart$' })
$taskSeeds = @($taskSeeds | Sort-Object -Unique)
$taskQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($taskPath in $taskSeeds) { $taskQueue.Enqueue($taskPath) }
$taskClosure = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$taskMissing = [System.Collections.Generic.List[string]]::new()
while ($taskQueue.Count -gt 0) {
  $taskPath = $taskQueue.Dequeue()
  if (-not $taskClosure.Add($taskPath)) { continue }
  $taskAbsolute = Join-Path $taskRepoRoot $taskPath
  if (-not (Test-Path -LiteralPath $taskAbsolute -PathType Leaf)) {
    $taskMissing.Add($taskPath)
    continue
  }
  $taskSource = [System.IO.File]::ReadAllText($taskAbsolute)
  # Test fixtures and generators hold Dart programs inside multiline strings.
  $taskSource = [regex]::Replace($taskSource, '(?s)r?(''{3}|"{3}).*?\1', '')
  foreach ($taskDirective in [regex]::Matches($taskSource, '(?ms)^\s*(?:import|export|part)\s+(''[^'']+''[^;]*);')) {
    foreach ($taskUriMatch in [regex]::Matches($taskDirective.Groups[1].Value, "'([^']+)'")) {
      $taskUri = $taskUriMatch.Groups[1].Value
      if ($taskUri.StartsWith('package:tapture/')) {
        $taskTarget = Join-Path $taskRepoRoot ('frontend/lib/' + $taskUri.Substring(16))
      } elseif ($taskUri.Contains(':')) { continue }
      else { $taskTarget = Join-Path (Split-Path -Parent $taskAbsolute) $taskUri }
      $taskResolved = [System.IO.Path]::GetFullPath($taskTarget)
      if ($taskResolved.StartsWith($taskRepoRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
        $taskQueue.Enqueue($taskResolved.Substring($taskRepoRoot.Length + 1).Replace('\','/'))
      }
    }
  }
}
$taskTracked = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($taskPath in (& git -C $taskRepoRoot ls-files -- frontend)) { [void]$taskTracked.Add($taskPath) }
$taskFixtures = @()
foreach ($taskFixtureName in @('catalogue','dependencies','naming','native_library','secrets','templates','whisper_vendor','whisper_wasm')) {
  foreach ($taskFile in (Get-ChildItem -LiteralPath (Join-Path $taskRepoRoot ('frontend/test/tool/fixtures/' + $taskFixtureName)) -Recurse -File)) {
    $taskFixtures += $taskFile.FullName.Substring($taskRepoRoot.Length + 1).Replace('\','/')
  }
}
foreach ($taskFile in (Get-ChildItem -LiteralPath (Join-Path $taskRepoRoot 'frontend/test/architecture/fixtures/data_safety') -Recurse -File)) {
  $taskFixtures += $taskFile.FullName.Substring($taskRepoRoot.Length + 1).Replace('\','/')
}
$taskCandidates = @(@($taskClosure) + $taskFixtures | Sort-Object -Unique)
$taskUntracked = @($taskCandidates | Where-Object { -not $taskTracked.Contains($_) })
$taskIgnored = @(& git -C $taskRepoRoot check-ignore -- $taskUntracked)
$taskResult = [ordered]@{
  Head = (& git -C $taskRepoRoot rev-parse HEAD)
  Roots = $taskSeeds
  SuiteCount = @($taskSeeds | Where-Object { $_.EndsWith('_test.dart') }).Count
  ClosureCount = $taskClosure.Count
  TrackedClosureCount = @($taskClosure | Where-Object { $taskTracked.Contains($_) }).Count
  Missing = @($taskMissing | Sort-Object)
  FixtureCount = $taskFixtures.Count
  Ignored = $taskIgnored
  UntrackedNotIgnored = @($taskUntracked | Where-Object { $_ -notin $taskIgnored })
}
$taskResult | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $taskRepoRoot 'frontend/build/task147/shipping-audit.json')
$taskResult | ConvertTo-Json -Depth 4
