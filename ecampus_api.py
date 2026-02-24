"""
PSG Bunker – eCampus Scraper API
FastAPI backend that scrapes PSG Tech eCampus and stores results in Supabase.
Deploy this on Render / Railway / any Python host.

Required env vars:
  SUPABASE_URL            - your Supabase project URL
  SUPABASE_SERVICE_KEY    - service-role key (NOT anon key)
  API_SECRET              - a shared secret so only your Flutter app can call sync
"""

import os
import math
import logging
from datetime import datetime, date

import requests
from bs4 import BeautifulSoup
from fastapi import FastAPI, HTTPException, Header, Query
from fastapi.middleware.cors import CORSMiddleware
from supabase import create_client, Client
from dotenv import load_dotenv

load_dotenv()

# ─── Logging ─────────────────────────────────────────────────────────────────
logging.basicConfig(level=logging.INFO, format="%(levelname)s | %(message)s")
log = logging.getLogger("ecampus_api")

# ─── Supabase client ─────────────────────────────────────────────────────────
SUPABASE_URL = os.environ.get("SUPABASE_URL", "")
SUPABASE_SERVICE_KEY = os.environ.get("SUPABASE_SERVICE_KEY", "")
API_SECRET = os.environ.get("API_SECRET", "psg-bunker-api-secret")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)

# ─── FastAPI app ─────────────────────────────────────────────────────────────
app = FastAPI(
    title="PSG Bunker eCampus API",
    description="Syncs attendance & CGPA data from PSG eCampus for all students",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── eCampus URLs ────────────────────────────────────────────────────────────
BASE_URL    = "https://ecampus.psgtech.ac.in/studzone2/"
ATT_URL     = BASE_URL + "AttWfPercView.aspx"
COURSE_URL  = BASE_URL + "AttWfStudTimtab.aspx"
RESULT_URL  = BASE_URL + "FrmEpsStudResult.aspx"

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}

# ─── Grade map ───────────────────────────────────────────────────────────────
GRADE_MAP = {
    "O": 10, "A+": 9, "A": 8, "B+": 7,
    "B": 6, "C+": 5, "C": 4, "RA": 0, "SA": 0, "W": 0,
}


def _dob_to_password(dob: date) -> str:
    """Convert a date object → eCampus password format (e.g. 08jul04)."""
    return dob.strftime("%d%b%y").lower()


# ─── Scraper helpers ─────────────────────────────────────────────────────────

def _ecampus_session(rollno: str, password: str) -> requests.Session:
    """Login to eCampus and return an authenticated session."""
    session = requests.Session()
    r = session.get(BASE_URL, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(r.text, "html.parser")

    def _val(sel: str) -> str:
        el = soup.select_one(sel)
        return el["value"] if el else ""

    payload = {
        "__VIEWSTATE": _val("#__VIEWSTATE"),
        "__VIEWSTATEGENERATOR": _val("#__VIEWSTATEGENERATOR"),
        "__EVENTVALIDATION": _val("#__EVENTVALIDATION"),
        "txtusercheck": rollno,
        "txtpwdcheck": password,
        "abcd3": "Login",
    }
    session.post(BASE_URL, data=payload, headers=HEADERS, timeout=20)
    return session


def _fetch_attendance(session: requests.Session) -> list[dict]:
    """Scrape raw attendance table rows."""
    page = session.get(ATT_URL, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(page.text, "html.parser")
    table = soup.find("table", {"class": "cssbody"})
    if not table:
        raise ValueError("Attendance table not found – login may have failed")

    rows = []
    for tr in table.find_all("tr"):
        cols = [td.text.strip() for td in tr.find_all("td")]
        cols = [c for c in cols if c]
        rows.append(cols)
    return rows


def _fetch_course_map(session: requests.Session) -> dict[str, str]:
    """Map course code → course title from timetable page."""
    page = session.get(COURSE_URL, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(page.text, "html.parser")
    table = soup.find("table", {"id": "TbCourDesc"})
    if not table:
        return {}
    mapping: dict[str, str] = {}
    for tr in table.find_all("tr")[1:]:
        cols = [td.text.strip() for td in tr.find_all("td")]
        if len(cols) >= 2:
            mapping[cols[0]] = cols[1]
    return mapping


def _parse_attendance(rows: list[list[str]], course_map: dict[str, str]) -> dict:
    """Convert raw rows into structured JSON for Supabase storage."""
    subjects = []
    for item in rows[1:]:          # skip header row
        if len(item) < 10:
            continue
        try:
            total_hours    = int(item[1])
            total_present  = int(item[4])
            pct            = float(item[5])
            course_code    = item[0]
            course_title   = course_map.get(course_code, course_code)

            subject: dict = {
                "course_code": course_code,
                "course_title": course_title,
                "total_hours": total_hours,
                "exception_hour": int(item[2]),
                "total_present": total_present,
                "percentage": round(pct, 2),
                "attendance_from": item[8],
                "attendance_to": item[9],
            }

            if pct < 75:
                subject["classes_to_attend"] = math.ceil(
                    (0.75 * total_hours - total_present) / 0.25
                )
                subject["can_bunk"] = 0
            else:
                subject["can_bunk"] = int(
                    (total_present - 0.75 * total_hours) / 0.75
                )
                subject["classes_to_attend"] = 0

            subjects.append(subject)
        except (ValueError, IndexError):
            continue

    total_hours   = sum(s["total_hours"]   for s in subjects)
    total_present = sum(s["total_present"] for s in subjects)
    overall_pct   = round((total_present / total_hours * 100) if total_hours > 0 else 0, 2)

    if overall_pct < 75:
        overall_can_bunk       = 0
        overall_need_to_attend = math.ceil(
            (0.75 * total_hours - total_present) / 0.25
        )
    else:
        overall_can_bunk       = int((total_present - 0.75 * total_hours) / 0.75)
        overall_need_to_attend = 0

    return {
        "subjects": subjects,
        "summary": {
            "total_hours":         total_hours,
            "total_present":       total_present,
            "overall_percentage":  overall_pct,
            "overall_can_bunk":    overall_can_bunk,
            "overall_need_attend": overall_need_to_attend,
        },
    }


def _fetch_cgpa(session: requests.Session) -> dict:
    """Scrape grade results and compute CGPA."""
    page = session.get(RESULT_URL, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(page.text, "html.parser")
    table = soup.find("table", {"id": "DgResult"})
    if not table:
        return {"error": "No results found"}

    courses = []
    for tr in table.find_all("tr")[1:]:
        cols = [td.text.strip() for td in tr.find_all("td")]
        if len(cols) >= 6:
            try:
                credits = int(cols[3])
            except ValueError:
                credits = 0
            courses.append({
                "semester": cols[0],
                "code": cols[1],
                "title": cols[2],
                "credits": credits,
                "grade": cols[4].split()[-1] if cols[4] else "",
                "result": cols[5],
            })

    total_points  = 0
    total_credits = 0
    semesters_seen: set[str] = set()

    for c in courses:
        grade_pts = GRADE_MAP.get(c["grade"].upper(), None)
        if grade_pts is not None and c["credits"] > 0:
            total_points  += c["credits"] * grade_pts
            total_credits += c["credits"]
        semesters_seen.add(c["semester"])

    cgpa = round(total_points / total_credits, 3) if total_credits > 0 else 0.0
    latest_sem = max(semesters_seen) if semesters_seen else ""

    # Per-semester SGPA
    sem_data: dict[str, dict] = {}
    for c in courses:
        sem = c["semester"]
        if sem not in sem_data:
            sem_data[sem] = {"points": 0, "credits": 0}
        gp = GRADE_MAP.get(c["grade"].upper(), None)
        if gp is not None and c["credits"] > 0:
            sem_data[sem]["points"]  += c["credits"] * gp
            sem_data[sem]["credits"] += c["credits"]

    semester_sgpa = [
        {
            "semester": sem,
            "sgpa": round(v["points"] / v["credits"], 3) if v["credits"] > 0 else 0.0,
        }
        for sem, v in sorted(sem_data.items())
    ]

    return {
        "cgpa": cgpa,
        "total_credits": total_credits,
        "latest_semester": latest_sem,
        "total_semesters": len(semesters_seen),
        "semester_sgpa": semester_sgpa,
        "courses": courses,
    }


# ─── Supabase helpers ─────────────────────────────────────────────────────────

def _get_user_dob(rollno: str) -> date:
    """Fetch DOB from Supabase whitelist table by reg_no."""
    result = (
        supabase.table("whitelist")
        .select("dob")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    if not result.data or not result.data.get("dob"):
        raise HTTPException(status_code=404, detail=f"Roll number {rollno} not found in whitelist")

    raw_dob = result.data["dob"]          # e.g. "2004-07-08"
    return datetime.strptime(raw_dob, "%Y-%m-%d").date()


def _upsert_attendance(rollno: str, data: dict) -> None:
    supabase.table("ecampus_attendance").upsert(
        {
            "reg_no": rollno,
            "data": data,
            "synced_at": datetime.utcnow().isoformat(),
        },
        on_conflict="reg_no",
    ).execute()


def _upsert_cgpa(rollno: str, data: dict) -> None:
    supabase.table("ecampus_cgpa").upsert(
        {
            "reg_no": rollno,
            "data": data,
            "synced_at": datetime.utcnow().isoformat(),
        },
        on_conflict="reg_no",
    ).execute()


def _read_attendance(rollno: str) -> dict | None:
    result = (
        supabase.table("ecampus_attendance")
        .select("data, synced_at")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    return result.data


def _read_cgpa(rollno: str) -> dict | None:
    result = (
        supabase.table("ecampus_cgpa")
        .select("data, synced_at")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    return result.data


# ─── API Routes ──────────────────────────────────────────────────────────────

def _check_secret(x_api_secret: str | None) -> None:
    if x_api_secret != API_SECRET:
        raise HTTPException(status_code=401, detail="Invalid API secret")


@app.get("/")
def health():
    return {"status": "ok", "service": "PSG Bunker eCampus API"}


@app.post("/api/ecampus/sync")
def sync_user(
    rollno: str = Query(..., description="Student roll number (e.g. 24I434)"),
    x_api_secret: str | None = Header(None),
):
    """
    Scrapes eCampus for the given roll number, computes attendance + CGPA,
    and stores the results in Supabase.  Call this whenever you want fresh data.
    Requires X-Api-Secret header.
    """
    _check_secret(x_api_secret)
    log.info(f"[sync] Starting sync for {rollno}")

    # 1. Resolve DOB → password
    dob    = _get_user_dob(rollno)
    password = _dob_to_password(dob)
    log.info(f"[sync] {rollno} – DOB resolved, logging in to eCampus")

    # 2. Authenticate
    try:
        session = _ecampus_session(rollno, password)
    except Exception as exc:
        log.error(f"[sync] Login failed for {rollno}: {exc}")
        raise HTTPException(status_code=502, detail=f"eCampus login failed: {exc}")

    # 3. Fetch attendance
    try:
        raw_rows   = _fetch_attendance(session)
        course_map = _fetch_course_map(session)
        att_data   = _parse_attendance(raw_rows, course_map)
    except ValueError as exc:
        raise HTTPException(status_code=502, detail=str(exc))

    # 4. Fetch CGPA
    cgpa_data = _fetch_cgpa(session)

    # 5. Store in Supabase
    _upsert_attendance(rollno, att_data)
    _upsert_cgpa(rollno, cgpa_data)
    log.info(f"[sync] {rollno} – data stored ✔")

    synced_at = datetime.utcnow().isoformat()
    return {
        "ok": True,
        "rollno": rollno,
        "synced_at": synced_at,
        "attendance_summary": att_data["summary"],
        "cgpa": cgpa_data.get("cgpa"),
    }


@app.get("/api/ecampus/attendance")
def get_attendance(
    rollno: str = Query(...),
    x_api_secret: str | None = Header(None),
):
    """Returns the latest cached attendance data from Supabase."""
    _check_secret(x_api_secret)
    row = _read_attendance(rollno)
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No attendance data found. Please sync first.",
        )
    return {"ok": True, "rollno": rollno, **row}


@app.get("/api/ecampus/cgpa")
def get_cgpa(
    rollno: str = Query(...),
    x_api_secret: str | None = Header(None),
):
    """Returns the latest cached CGPA data from Supabase."""
    _check_secret(x_api_secret)
    row = _read_cgpa(rollno)
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No CGPA data found. Please sync first.",
        )
    return {"ok": True, "rollno": rollno, **row}


@app.post("/api/ecampus/sync-all")
def sync_all_users(x_api_secret: str | None = Header(None)):
    """
    Syncs eCampus data for ALL students in the whitelist that have a DOB set.
    Useful for a scheduled cron job (run nightly).  Returns a summary.
    """
    _check_secret(x_api_secret)

    result = (
        supabase.table("whitelist")
        .select("reg_no, dob")
        .not_.is_("dob", "null")
        .not_.is_("reg_no", "null")
        .execute()
    )
    students = result.data or []
    log.info(f"[sync-all] Found {len(students)} students with DOB")

    success, failed = [], []
    for s in students:
        rollno = s["reg_no"]
        try:
            dob      = datetime.strptime(s["dob"], "%Y-%m-%d").date()
            password = _dob_to_password(dob)
            session  = _ecampus_session(rollno, password)
            raw_rows   = _fetch_attendance(session)
            course_map = _fetch_course_map(session)
            att_data   = _parse_attendance(raw_rows, course_map)
            cgpa_data  = _fetch_cgpa(session)
            _upsert_attendance(rollno, att_data)
            _upsert_cgpa(rollno, cgpa_data)
            success.append(rollno)
            log.info(f"[sync-all] ✔ {rollno}")
        except Exception as exc:
            failed.append({"rollno": rollno, "error": str(exc)})
            log.error(f"[sync-all] ✗ {rollno}: {exc}")

    return {
        "ok": True,
        "total": len(students),
        "success_count": len(success),
        "failed_count": len(failed),
        "failed": failed,
        "synced_at": datetime.utcnow().isoformat(),
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("ecampus_api:app", host="0.0.0.0", port=8000, reload=True)
