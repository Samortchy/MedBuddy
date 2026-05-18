# MedBuddy API Test Script — auto-login edition
# Usage: .\test_api.ps1
# Credentials can be overridden: .\test_api.ps1 -Email "other@mail.com" -Password "pass"

param(
    [string]$Email    = "test@medbuddy.com",
    [string]$Password = "Test123456!"
)

$BASE          = "http://localhost:8000/api/v1"
$SUPABASE_URL  = "https://tcyrehuatbtlfvnttkgc.supabase.co"
$ANON_KEY      = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRjeXJlaHVhdGJ0bGZ2bnR0a2djIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc1ODI3NzUsImV4cCI6MjA5MzE1ODc3NX0.MJsuJRl0GDqKo1a-eVBYNEjrD98DHG2g0F6Pcz5RkC8"

# ── 1. Sign in via Supabase to get a real JWT ──────────────────────────────────
Write-Host "Signing in as $Email ..." -ForegroundColor Cyan
$loginBody = @{ email = $Email; password = $Password } | ConvertTo-Json

$loginParams = @{
    Method          = "POST"
    Uri             = "$SUPABASE_URL/auth/v1/token?grant_type=password"
    Headers         = @{ apikey = $ANON_KEY; "Content-Type" = "application/json" }
    Body            = $loginBody
    UseBasicParsing = $true
    ErrorAction     = "Stop"
}

try {
    $loginResp = Invoke-WebRequest @loginParams
    $Token = ($loginResp.Content | ConvertFrom-Json).access_token
    Write-Host "[200] Login OK — token obtained" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Login failed: $($_.ErrorDetails.Message)" -ForegroundColor Red
    exit 1
}

$H = @{ Authorization = "Bearer $Token"; "Content-Type" = "application/json" }

# ── Helper ─────────────────────────────────────────────────────────────────────
function Req {
    param($Label, $Method, $Path, $Body = $null)
    try {
        $p = @{ Method = $Method; Uri = "$BASE$Path"; Headers = $H; UseBasicParsing = $true }
        if ($Body) {
            $p.Body = ($Body | ConvertTo-Json -Depth 5)
        }
        $r = Invoke-WebRequest @p -ErrorAction Stop
        Write-Host "[$($r.StatusCode)] $Label" -ForegroundColor Green
        return $r.Content | ConvertFrom-Json
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__
        Write-Host "[$code] $Label" -ForegroundColor Red
        try {
            $_.ErrorDetails.Message | ConvertFrom-Json | ConvertTo-Json -Depth 3
        }
        catch {
            $_.ErrorDetails.Message
        }
        return $null
    }
}

$today = (Get-Date -Format "yyyy-MM-dd")
Write-Host ""

# ── PATIENT PROFILE ────────────────────────────────────────────────────────────
Req "GET  /patient/profile"  GET  "/patient/profile" | Out-Null
Req "PATCH /patient/profile" PATCH "/patient/profile" @{ full_name = "Test Patient"; checkin_frequency = 1 } | Out-Null

# ── MEDICATIONS ────────────────────────────────────────────────────────────────
$meds = Req "GET  /medications/" GET "/medications/"

$newMedBody = @{
    name       = "Test Panadol"
    dose_amount = 500
    dose_unit  = "mg"
    frequency  = "daily"
    start_date = $today
    schedules  = @(@{ time_of_day = "08:00" })
}
$newMed = Req "POST /medications/ (daily)" POST "/medications/" $newMedBody

if ($newMed) {
    $medId = $newMed.id
    Req "PATCH /medications/$medId"  PATCH  "/medications/$medId"  @{ name = "Test Panadol 500mg" } | Out-Null
    Req "DELETE /medications/$medId" DELETE "/medications/$medId" | Out-Null
}

# ── DOSE LOGS ─────────────────────────────────────────────────────────────────
$doses = Req "GET  /dose-logs/?date=$today" GET "/dose-logs/?date=$today"
if ($doses -and $doses.Count -gt 0) {
    $doseId = $doses[0].dose_id
    Req "POST /dose-logs/ (mark taken)" POST "/dose-logs/" @{ dose_id = $doseId; status = "taken" } | Out-Null
}
else {
    Write-Host "[SKIP] No doses to mark — add a medication first and re-run" -ForegroundColor Yellow
}

# ── HEALTH CONDITIONS ──────────────────────────────────────────────────────────
Req "GET  /health-conditions/" GET "/health-conditions/" | Out-Null
$cond = Req "POST /health-conditions/" POST "/health-conditions/" @{ name = "Test Condition"; notes = "chronic" }
if ($cond) {
    Req "DELETE /health-conditions/$($cond.id)" DELETE "/health-conditions/$($cond.id)" | Out-Null
}

# ── EMERGENCY CONTACTS ────────────────────────────────────────────────────────
Req "GET  /emergency-contacts/" GET "/emergency-contacts/" | Out-Null
$contact = Req "POST /emergency-contacts/" POST "/emergency-contacts/" @{
    name         = "Test Contact"
    phone        = "+1234567890"
    priority     = 1
    relationship = "Friend"
}
if ($contact) {
    Req "PATCH /emergency-contacts/$($contact.id)"  PATCH  "/emergency-contacts/$($contact.id)"  @{ name = "Updated Contact" } | Out-Null
    Req "DELETE /emergency-contacts/$($contact.id)" DELETE "/emergency-contacts/$($contact.id)" | Out-Null
}

# ── WELLNESS CHECKINS ──────────────────────────────────────────────────────────
Req "GET  /wellness-checkins/" GET "/wellness-checkins/" | Out-Null
$checkinBody = @{
    mood_score    = 3
    energy_score  = 3
    pain_level    = 2
    sleep_quality = 3
    meds_confirmed = $true
}
Req "POST /wellness-checkins/" POST "/wellness-checkins/" $checkinBody | Out-Null

# ── VISIT SUMMARIES ────────────────────────────────────────────────────────────
Req "GET  /visit-summaries/" GET "/visit-summaries/" | Out-Null
Req "POST /visit-summaries/" POST "/visit-summaries/" @{ raw_transcript = "Patient visited. Blood pressure normal." } | Out-Null

# ── SYMPTOM LOGS ───────────────────────────────────────────────────────────────
Req "POST /symptom-logs/" POST "/symptom-logs/" @{ body = "Mild headache this morning." } | Out-Null

# ── APPOINTMENTS ──────────────────────────────────────────────────────────────
Req "GET  /appointments/" GET "/appointments/" | Out-Null

Write-Host ""
Write-Host "Done. RED = needs fixing, YELLOW = skipped (dependency), GREEN = OK" -ForegroundColor Yellow