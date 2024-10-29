If ($RecallEnabled.State -eq "Enabled")
{
  Disable-WindowsOptionalFeature -FeatureName "Recall" -Online
} else {
  Write-Host "Recall is disabled"
}

