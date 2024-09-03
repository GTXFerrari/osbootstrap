# Enable Dark-Mode (VM)
Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name SystemUsesLightTheme -Value 0
Set-ItemProperty -Path REGISTRY::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
