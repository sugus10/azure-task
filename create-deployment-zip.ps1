# PowerShell script to create deployment zip with proper folder structure

# Remove old zip if exists
if (Test-Path deployment.zip) {
    Remove-Item deployment.zip -Force
}

Write-Host "Creating deployment package with proper folder structure..."

# Get current directory
$currentDir = Get-Location

# Create a temporary directory for proper zip structure
$tempDir = Join-Path $env:TEMP "deployment-$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Copy files maintaining structure
    Copy-Item -Path "server.js" -Destination $tempDir -Force
    Copy-Item -Path "package.json" -Destination $tempDir -Force
    Copy-Item -Path "public" -Destination $tempDir -Recurse -Force
    
    if (Test-Path ".deployment") {
        Copy-Item -Path ".deployment" -Destination $tempDir -Force
    }
    
    Write-Host "Files copied to temp directory:"
    Get-ChildItem -Recurse $tempDir | Select-Object FullName
    
    # Create zip from temp directory
    Write-Host "Creating zip file..."
    Compress-Archive -Path "$tempDir\*" -DestinationPath deployment.zip -Force
    
    Write-Host "✓ Deployment package created: deployment.zip"
    
    # Verify structure
    Write-Host "Verifying package structure..."
    $verifyTemp = Join-Path $env:TEMP "verify-$(Get-Random)"
    Expand-Archive -Path deployment.zip -DestinationPath $verifyTemp -Force
    
    if (Test-Path "$verifyTemp\public\index.html") {
        Write-Host "✓ Package structure correct: public/index.html exists"
    } else {
        Write-Host "✗ ERROR: Package structure incorrect!"
        Write-Host "Files in package:"
        Get-ChildItem -Recurse $verifyTemp | Select-Object FullName
    }
    
    Remove-Item -Recurse -Force $verifyTemp
}
finally {
    # Clean up temp directory
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir
    }
}

