$taskAuditRoot = 'D:\coding\apps\flutter\tapture'
$taskAuditPlan = Get-Content -LiteralPath (Join-Path $taskAuditRoot 'dev-plan/24-product-refinements.md') -Raw
$taskAuditSection = ($taskAuditPlan -split '(?m)^## 144 — ', 2)[1]
$taskAuditSection = ($taskAuditSection -split '(?m)^## \d{3} — ', 2)[0]
$taskAuditSeeds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($match in [regex]::Matches($taskAuditSection, 'frontend/(?:test|integration_test)/[^`\s:]+\.dart')) {
  [void]$taskAuditSeeds.Add($match.Value)
}
foreach ($path in @(
  'frontend/test/core/assets/ai_provider_assets_test.dart',
  'frontend/test/core/widgets/fields/app_choice_field_branding_test.dart',
  'frontend/test/features/account/presentation/account_connection_panel_test.dart',
  'frontend/test/features/capture/presentation/import_capture_document_test.dart',
  'frontend/test/features/processing/presentation/queue_screen_test.dart',
  'frontend/test/features/settings/presentation/storage_navigation_test.dart'
)) { [void]$taskAuditSeeds.Add($path) }
$taskAuditQueue = [System.Collections.Generic.Queue[string]]::new()
foreach ($path in $taskAuditSeeds) { $taskAuditQueue.Enqueue($path) }
$taskAuditClosure = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$taskAuditMissing = [System.Collections.Generic.List[string]]::new()
while ($taskAuditQueue.Count -gt 0) {
  $path = $taskAuditQueue.Dequeue()
  if (-not $taskAuditClosure.Add($path)) { continue }
  $absolute = Join-Path $taskAuditRoot $path
  if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
    $taskAuditMissing.Add($path)
    continue
  }
  $source = Get-Content -LiteralPath $absolute -Raw
  foreach ($directive in [regex]::Matches($source, '(?ms)^\s*(?:import|export|part)\s+(''[^'']+''[^;]*);')) {
    foreach ($uriMatch in [regex]::Matches($directive.Groups[1].Value, "'([^']+)'")) {
      $uri = $uriMatch.Groups[1].Value
      if ($uri.StartsWith('package:tapture/')) {
        $target = Join-Path $taskAuditRoot ('frontend/lib/' + $uri.Substring(16))
      } elseif ($uri.Contains(':')) { continue }
      else { $target = Join-Path (Split-Path -Parent $absolute) $uri }
      $resolved = [System.IO.Path]::GetFullPath($target)
      if (-not $resolved.StartsWith($taskAuditRoot + '\', [System.StringComparison]::OrdinalIgnoreCase)) { continue }
      $relative = $resolved.Substring($taskAuditRoot.Length + 1).Replace('\', '/')
      $taskAuditQueue.Enqueue($relative)
    }
  }
}
$taskAuditGoldenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$taskAuditThemes = @('light', 'dark', 'outdoor')
foreach ($corner in @('compact', 'compact_landscape_text2', 'medium', 'expanded_text2')) {
  foreach ($theme in $taskAuditThemes) {
    foreach ($pair in @(
      @('frontend/test/features/capture/presentation/goldens', 'capture_composition'),
      @('frontend/test/features/projects/presentation/goldens', 'project_process_menu'),
      @('frontend/test/features/projects/presentation/goldens', 'project_export_completed'),
      @('frontend/test/core/widgets/fields/goldens', 'choice_branded'),
      @('frontend/test/core/widgets/fields/goldens', 'choice_branded_sheet'),
      @('frontend/test/features/records/presentation/goldens', 'recycle_bin')
    )) { [void]$taskAuditGoldenPaths.Add("$($pair[0])/$($pair[1])_${corner}_${theme}.png") }
  }
}
foreach ($corner in @('compact_landscape_text2', 'medium_portrait', 'expanded_landscape_text2')) {
  foreach ($theme in $taskAuditThemes) {
    foreach ($prefix in @('language_expanded', 'language_collapsed', 'ai_provider_settings')) {
      [void]$taskAuditGoldenPaths.Add("frontend/test/features/settings/presentation/goldens/${prefix}_${corner}_${theme}.png")
    }
  }
}
foreach ($theme in $taskAuditThemes) {
  [void]$taskAuditGoldenPaths.Add("frontend/test/features/projects/presentation/goldens/export_summary_${theme}.png")
  foreach ($scale in @(1, 2)) {
    [void]$taskAuditGoldenPaths.Add("frontend/test/features/settings/presentation/goldens/language_collapsed_${theme}_${scale}x.png")
    $suffix = if ($scale -eq 2) { '_text2' } else { '' }
    [void]$taskAuditGoldenPaths.Add("frontend/test/features/settings/presentation/goldens/ai_provider_settings${suffix}_${theme}.png")
    [void]$taskAuditGoldenPaths.Add("frontend/test/features/settings/presentation/goldens/settings_index_text${scale}_${theme}.png")
  }
}
foreach ($suffix in @('', '_text2')) {
  [void]$taskAuditGoldenPaths.Add("frontend/test/features/settings/presentation/goldens/ai_provider_settings${suffix}_system.png")
}
$taskAuditPaths = @($taskAuditClosure) + @($taskAuditGoldenPaths) | Sort-Object -Unique
$taskAuditTracked = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($path in (& git -C $taskAuditRoot ls-files -- frontend)) { [void]$taskAuditTracked.Add($path) }
$taskAuditUntracked = @($taskAuditPaths | Where-Object { -not $taskAuditTracked.Contains($_) })
$taskAuditIgnored = @(& git -C $taskAuditRoot check-ignore -- $taskAuditUntracked)
$taskAuditResult = [ordered]@{
  roots = @($taskAuditSeeds | Sort-Object)
  closureCount = $taskAuditClosure.Count
  missing = @($taskAuditMissing | Sort-Object)
  goldenCount = $taskAuditGoldenPaths.Count
  expectedGoldensNotYetCreated = @($taskAuditGoldenPaths | Where-Object { -not (Test-Path -LiteralPath (Join-Path $taskAuditRoot $_)) } | Sort-Object)
  untrackedClosure = @($taskAuditClosure | Where-Object { -not $taskAuditTracked.Contains($_) } | Sort-Object)
  untrackedGoldenCount = @($taskAuditGoldenPaths | Where-Object { -not $taskAuditTracked.Contains($_) }).Count
  ignoredUntracked = $taskAuditIgnored
}
$taskAuditResult | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $taskAuditRoot '.tmp-task144-shipping-audit.json')
$taskAuditResult | ConvertTo-Json -Depth 5
