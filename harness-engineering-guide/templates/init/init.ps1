# init.ps1 — Boot dev environment and verify health (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "=== Environment Recovery ==="

Write-Host "[1/5] Installing dependencies..."
if (Test-Path "package.json") {
    npm ci --silent
}
elseif (Test-Path "requirements.txt") {
    pip install -r requirements.txt -q
}
elseif (Test-Path "pyproject.toml") {
    try { uv sync -q } catch { pip install -e ".[dev]" -q }
}
elseif (Test-Path "go.mod") {
    go mod download
}
elseif (Test-Path "Cargo.toml") {
    cargo fetch
}
elseif (Test-Path "Gemfile") {
    bundle install --quiet
}
elseif (Test-Path "pubspec.yaml") {
    if (Test-Path "lib/main.dart") { flutter pub get } else { dart pub get }
}
else {
    Write-Host "No recognized package manager found"
}

Write-Host "[2/5] Building..."
if (Test-Path "package.json") {
    npm run build 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "BUILD FAILED"; exit 1 }
}
elseif (Test-Path "Cargo.toml") {
    cargo build 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "BUILD FAILED"; exit 1 }
}
elseif (Test-Path "go.mod") {
    go build ./... 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "BUILD FAILED"; exit 1 }
}

Write-Host "[3/5] Lint check..."
if (Test-Path "package.json") {
    npm run lint 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "LINT WARNINGS" }
}
elseif ((Test-Path "pyproject.toml") -or (Test-Path "ruff.toml")) {
    ruff check . 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "LINT WARNINGS" }
}
elseif (Test-Path "Cargo.toml") {
    cargo clippy 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Host "LINT WARNINGS" }
}

Write-Host "[4/5] Running tests..."
if (Test-Path "package.json") {
    npm test 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "TESTS FAILING"; exit 1 }
}
elseif ((Test-Path "pytest.ini") -or (Test-Path "pyproject.toml")) {
    pytest --tb=short 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "TESTS FAILING"; exit 1 }
}
elseif (Test-Path "go.mod") {
    go test ./... 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "TESTS FAILING"; exit 1 }
}
elseif (Test-Path "Cargo.toml") {
    cargo test 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "TESTS FAILING"; exit 1 }
}

Write-Host "[5/5] Environment health check..."
Write-Host ""
Write-Host "=== Environment Ready ==="
