# setup_project.ps1
# Godot Projekt Struktur Setup für PowerShell
# Ausführung in VSC PowerShell Terminal: .\setup_project.ps1
# Nutzung: PowerShell ausführen mit: powershell -ExecutionPolicy Bypass -File setup_project.ps1

$folders = @(
    "res://scripts",
    "res://scripts/managers",
    "res://scripts/managers/grid",
    "res://scripts/managers/turn",
    "res://scripts/managers/vision",
    "res://scripts/managers/combat",
    "res://scripts/systems",
    "res://scripts/systems/pathfinding",
    "res://scripts/systems/input",
    "res://scripts/systems/movement",
    "res://scripts/systems/targeting",
    "res://scripts/components",
    "res://scripts/components/unit",
    "res://scripts/components/grid",
    "res://scripts/components/facing",
    "res://scripts/entities",
    "res://scripts/handlers",
    "res://scripts/handlers/input",
    "res://scripts/handlers/events",
    "res://scripts/utils",
    "res://scripts/utils/math",
    "res://scripts/utils/debug",
    "res://scripts/utils/helpers",
    
    "res://scenes",
    "res://scenes/maps",
    "res://scenes/maps/map_01",
    "res://scenes/ui",
    "res://scenes/ui/main_menu",
    "res://scenes/ui/hud",
    "res://scenes/ui/panels",
    "res://scenes/entities",
    "res://scenes/entities/units",
    "res://scenes/entities/cover",
    "res://scenes/entities/markers",
    
    "res://resources",
    "res://resources/tilemaps",
    "res://resources/units",
    "res://resources/units/player",
    "res://resources/units/enemies",
    "res://resources/weapons",
    "res://resources/markers",
    "res://resources/markers/spawn",
    "res://resources/markers/waypoint",
    "res://resources/markers/objective",
    
    "res://assets",
    "res://assets/textures",
    "res://assets/models",
    "res://assets/audio",
    "res://assets/audio/sfx",
    "res://assets/audio/music"
)

$projectPath = Get-Location
Write-Host "Erstelle Ordnerstruktur in: $projectPath`n"

foreach ($folder in $folders) {
    # Entferne "res://" und ersetze mit aktuellem Pfad
    $cleanFolder = $folder -replace "res://", ""
    $folderPath = Join-Path $projectPath $cleanFolder
    
    if (-not (Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
        Write-Host "✅ Created: $cleanFolder"
    } else {
        Write-Host "⚠️  Exists: $cleanFolder"
    }
}

Write-Host "`n🎉 Ordnerstruktur erstellt!"
Write-Host "Oeffne jetzt Godot und importiere das Projekt"