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
API_SECRET = os.environ.get("API_SECRET", "change-me-to-a-long-random-string")

_supabase: Client | None = None


def _get_supabase() -> Client:
    """Create and cache the Supabase client on first use."""
    global _supabase
    if _supabase is not None:
        return _supabase
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        log.error("Supabase env vars are missing")
        raise HTTPException(
            status_code=500,
            detail="Supabase not configured. Set SUPABASE_URL and SUPABASE_SERVICE_KEY.",
        )
    try:
        _supabase = create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    except Exception as exc:
        log.error(f"Supabase init failed: {exc}")
        raise HTTPException(
            status_code=500,
            detail="Supabase configuration invalid. Check SUPABASE_SERVICE_KEY.",
        )
    return _supabase


def _get_bearer_token(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(" ")
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1]
    return None


def _require_placement_rep(authorization: str | None) -> str:
    token = _get_bearer_token(authorization)
    if not token:
        raise HTTPException(status_code=401, detail="Missing bearer token")

    sb = _get_supabase()
    try:
        user_res = sb.auth.get_user(token)
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid auth token")

    user = getattr(user_res, "user", None)
    if user is None and isinstance(user_res, dict):
        user = user_res.get("user")

    user_id = getattr(user, "id", None) if user is not None else None
    if user_id is None and isinstance(user, dict):
        user_id = user.get("id")

    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid auth token")

    role_row = (
        sb.table("users")
        .select("roles")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    roles = role_row.data.get("roles") if role_row.data else None
    if not isinstance(roles, dict) or not roles.get("isPlacementRep", False):
        raise HTTPException(status_code=403, detail="Placement rep access required")

    return user_id

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
CA_URL      = BASE_URL + "FrmCaStudMarkView.aspx"

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


# Locale-independent month abbreviations (PSG eCampus expects English)
_MONTH_ABBR = ["jan", "feb", "mar", "apr", "may", "jun",
               "jul", "aug", "sep", "oct", "nov", "dec"]


def _dob_to_password(dob: date) -> str:
    """Convert a date → eCampus password (e.g. 08jul04).
    Uses a hard-coded English month table so the result is the same
    regardless of the server's locale setting.
    """
    return f"{dob.day:02d}{_MONTH_ABBR[dob.month - 1]}{dob.strftime('%y')}"


def _parse_dob_value(value) -> date:
    """Robustly parse a DOB coming from Supabase.
    Handles: date object, plain string '2004-07-08',
    ISO datetime '2004-07-08T00:00:00', timezone-aware '2004-07-08T00:00:00+00:00'.
    """
    if isinstance(value, date) and not isinstance(value, datetime):
        return value
    if isinstance(value, datetime):
        return value.date()
    # String fallback – take the first 10 chars (YYYY-MM-DD)
    s = str(value).strip()
    return datetime.strptime(s[:10], "%Y-%m-%d").date()


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
    """Fetch DOB from Supabase whitelist or users table by reg_no."""
    sb = _get_supabase()
    result = (
        sb.table("whitelist")
        .select("dob")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )

    raw_dob = result.data.get("dob") if result.data else None
    if not raw_dob:
        user_row = (
            sb.table("users")
            .select("dob")
            .eq("reg_no", rollno)
            .maybe_single()
            .execute()
        )
        raw_dob = user_row.data.get("dob") if user_row.data else None

    if not raw_dob:
        raise HTTPException(
            status_code=404,
            detail=f"DOB not found for roll number {rollno}. "
                   "Please set the student's date of birth in the whitelist.",
        )

    # Use centralised robust parser (handles date objects, plain strings,
    # ISO datetime strings with or without timezone)
    dob_value = _parse_dob_value(raw_dob)

    # Write-back: if DOB came from users table, persist it to whitelist
    if result.data is not None and not result.data.get("dob"):
        sb.table("whitelist").update({"dob": dob_value.isoformat()}).eq(
            "reg_no", rollno
        ).execute()
        log.info(f"[dob] wrote back DOB {dob_value} to whitelist for {rollno}")

    return dob_value


def _upsert_attendance(rollno: str, data: dict) -> None:
    _get_supabase().table("ecampus_attendance").upsert(
        {
            "reg_no": rollno,
            "data": data,
            "synced_at": datetime.utcnow().isoformat(),
        },
        on_conflict="reg_no",
    ).execute()


def _upsert_cgpa(rollno: str, data: dict) -> None:
    _get_supabase().table("ecampus_cgpa").upsert(
        {
            "reg_no": rollno,
            "data": data,
            "synced_at": datetime.utcnow().isoformat(),
        },
        on_conflict="reg_no",
    ).execute()


def _upsert_bunked(rollno: str, subjects: list[dict]) -> None:
    if not subjects:
        return

    rows = []
    synced_at = datetime.utcnow().isoformat()
    for s in subjects:
        rows.append(
            {
                "reg_no": rollno,
                "course_code": s.get("course_code"),
                "course_title": s.get("course_title"),
                "total_hours": s.get("total_hours", 0),
                "total_present": s.get("total_present", 0),
                "percentage": s.get("percentage"),
                "can_bunk": s.get("can_bunk", 0),
                "need_attend": s.get("classes_to_attend", 0),
                "synced_at": synced_at,
            }
        )

    _get_supabase().table("ecampus_bunked_subjects").upsert(
        rows,
        on_conflict="reg_no,course_code",
    ).execute()


def _read_attendance(rollno: str) -> dict | None:
    result = (
        _get_supabase().table("ecampus_attendance")
        .select("data, synced_at")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    return result.data


def _read_cgpa(rollno: str) -> dict | None:
    result = (
        _get_supabase().table("ecampus_cgpa")
        .select("data, synced_at")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    return result.data


def _fetch_ca_marks(session: requests.Session) -> list[list[str]]:
    """Scrape CA (Continuous Assessment) internal marks table."""
    page = session.get(CA_URL, headers=HEADERS, timeout=20)
    soup = BeautifulSoup(page.text, "html.parser")
    # PSG eCampus shows CA marks in a table with id 'DgCamarks' or similar.
    # We try multiple selectors to stay robust across portal upgrades.
    table = (
        soup.find("table", {"id": "DgCamarks"})
        or soup.find("table", {"id": "GvCaMark"})
        or soup.find("table", {"id": "gvCAMark"})
        or soup.find("table", {"class": "cssbody"})
    )
    if not table:
        return []  # CA marks not available yet (portal hasn't published them)

    rows: list[list[str]] = []
    for tr in table.find_all("tr"):
        cols = [td.get_text(separator=" ", strip=True) for td in tr.find_all("td")]
        cols = [c for c in cols if c]  # drop empty cells
        if cols:
            rows.append(cols)
    return rows


def _parse_ca_marks(rows: list[list[str]]) -> dict:
    """
    Parse raw CA marks table rows into a structured dict.

    PSG eCampus CA marks table columns (typical):
      0: Course Code
      1: Course Title
      2: Assessment type (CA1 / CA2)
      3: Marks Obtained
      4: Maximum Marks
    OR (older portal layout where each row is one subject with CA1 & CA2 inline):
      0: S.No
      1: Course Code
      2: Course Title
      3: CA1 marks
      4: CA1 max
      5: CA2 marks   (may be absent / '--' / '0' if not conducted)
      6: CA2 max
    We auto-detect the layout by inspecting column count.
    """
    if not rows:
        return {"subjects": [], "note": "CA marks not published yet"}

    # ── Detect layout ────────────────────────────────────────────────────────
    sample = rows[0]

    def _safe_float(v: str) -> float | None:
        v = v.strip().replace("--", "").replace("-", "")
        try:
            return float(v) if v else None
        except ValueError:
            return None

    subjects_dict: dict[str, dict] = {}

    # Layout A: each row = one test for one course (multiple rows per course)
    # Typical cols: [code, title, 'CA1'/'CA2', marks, max_marks]
    if len(sample) >= 5 and any(
        kw in " ".join(sample).upper() for kw in ("CA1", "CA2", "CA-1", "CA-2")
    ):
        for row in rows:
            if len(row) < 4:
                continue
            code    = row[0].strip()
            title   = row[1].strip() if len(row) > 1 else code
            ca_type = row[2].strip().upper().replace("-", "").replace(" ", "")
            mark    = _safe_float(row[3])
            max_m   = _safe_float(row[4]) if len(row) > 4 else None

            # Skip header rows
            if not code or code.upper() in ("COURSE CODE", "S.NO", "NO"):
                continue

            if code not in subjects_dict:
                subjects_dict[code] = {
                    "course_code": code,
                    "course_title": title,
                    "ca_tests": [],
                }

            if ca_type in ("CA1", "CA-1", "FIRSTCA"):
                test_label = "CA1"
            elif ca_type in ("CA2", "CA-2", "SECONDCA"):
                test_label = "CA2"
            else:
                test_label = ca_type or "CA"

            pct = round(mark / max_m * 100, 2) if mark is not None and max_m else None
            subjects_dict[code]["ca_tests"].append({
                "test": test_label,
                "marks": mark,
                "max_marks": max_m,
                "percentage": pct,
            })

    else:
        # Layout B: each row = one subject, CA1 & CA2 columns inline
        # Typical cols: [sno, code, title, ca1_marks, ca1_max, ca2_marks, ca2_max]
        for row in rows:
            n = len(row)
            if n < 3:
                continue
            # Try to find the code column (skip S.No)
            offset = 0
            if n >= 7 and row[0].replace(".", "").strip().isdigit():
                offset = 1
            code  = row[offset].strip()
            title = row[offset + 1].strip() if n > offset + 1 else code

            if not code or code.upper() in ("COURSE CODE", "S.NO", "NO"):
                continue

            ca_tests = []
            ca1_m   = _safe_float(row[offset + 2]) if n > offset + 2 else None
            ca1_max = _safe_float(row[offset + 3]) if n > offset + 3 else None
            ca2_m   = _safe_float(row[offset + 4]) if n > offset + 4 else None
            ca2_max = _safe_float(row[offset + 5]) if n > offset + 5 else None

            if ca1_m is not None or ca1_max is not None:
                pct = round(ca1_m / ca1_max * 100, 2) if ca1_m and ca1_max else None
                ca_tests.append({"test": "CA1", "marks": ca1_m, "max_marks": ca1_max, "percentage": pct})

            if ca2_m is not None or ca2_max is not None:
                pct = round(ca2_m / ca2_max * 100, 2) if ca2_m and ca2_max else None
                ca_tests.append({"test": "CA2", "marks": ca2_m, "max_marks": ca2_max, "percentage": pct})

            if ca_tests:
                subjects_dict[code] = {
                    "course_code": code,
                    "course_title": title,
                    "ca_tests": ca_tests,
                }

    subjects = list(subjects_dict.values())
    return {"subjects": subjects}


def _upsert_ca_marks(rollno: str, data: dict) -> None:
    _get_supabase().table("ecampus_ca_marks").upsert(
        {
            "reg_no": rollno,
            "data": data,
            "synced_at": datetime.utcnow().isoformat(),
        },
        on_conflict="reg_no",
    ).execute()


def _read_ca_marks(rollno: str) -> dict | None:
    result = (
        _get_supabase().table("ecampus_ca_marks")
        .select("data, synced_at")
        .eq("reg_no", rollno)
        .maybe_single()
        .execute()
    )
    return result.data


def _sync_single_rollno(rollno: str, dob_value: date) -> tuple[dict, dict, dict]:
    """Sync one student end-to-end and return (attendance, cgpa, ca_marks) payloads."""
    password = _dob_to_password(dob_value)
    session = _ecampus_session(rollno, password)
    raw_rows = _fetch_attendance(session)
    course_map = _fetch_course_map(session)
    att_data = _parse_attendance(raw_rows, course_map)
    cgpa_data = _fetch_cgpa(session)
    # CA marks – non-fatal: if the page isn’t available yet we store an empty payload
    try:
        ca_raw = _fetch_ca_marks(session)
        ca_data = _parse_ca_marks(ca_raw)
    except Exception as exc:
        log.warning(f"[sync] {rollno} – CA marks unavailable: {exc}")
        ca_data = {"subjects": [], "note": "CA marks page unavailable"}
    _upsert_attendance(rollno, att_data)
    _upsert_cgpa(rollno, cgpa_data)
    _upsert_bunked(rollno, att_data.get("subjects", []))
    _upsert_ca_marks(rollno, ca_data)
    return att_data, cgpa_data, ca_data
    return att_data, cgpa_data


def _get_whitelist_students_with_dob() -> list[dict]:
    sb = _get_supabase()
    whitelist_rows = (
        sb.table("whitelist")
        .select("reg_no, dob")
        .not_.is_("reg_no", "null")
        .order("reg_no")
        .execute()
    ).data or []

    users_rows = (
        sb.table("users")
        .select("reg_no, dob")
        .not_.is_("reg_no", "null")
        .not_.is_("dob", "null")
        .execute()
    ).data or []

    users_dob = {r.get("reg_no"): r.get("dob") for r in users_rows if r.get("reg_no")}
    merged: list[dict] = []
    writeback_rows: list[dict] = []   # bulk write-back DOBs found in users but not whitelist

    for row in whitelist_rows:
        reg_no = row.get("reg_no")
        if not reg_no:
            continue
        dob = row.get("dob") or users_dob.get(reg_no)
        if not dob:
            log.warning(f"[whitelist] {reg_no} – no DOB found in whitelist or users; skipping sync")
            continue

        if not row.get("dob") and users_dob.get(reg_no):
            # Parse first so we always write the canonical YYYY-MM-DD string
            try:
                dob_parsed = _parse_dob_value(dob)
                writeback_rows.append({"reg_no": reg_no, "dob": dob_parsed.isoformat()})
            except Exception:
                pass  # keep going even if parse fails; sync will surface the error

        merged.append({"reg_no": reg_no, "dob": dob})

    # Bulk write-back discovered DOBs to whitelist (one call per row to avoid upsert issues)
    for wb in writeback_rows:
        try:
            sb.table("whitelist").update({"dob": wb["dob"]}).eq("reg_no", wb["reg_no"]).execute()
            log.info(f"[whitelist] wrote back DOB {wb['dob']} for {wb['reg_no']}")
        except Exception as e:
            log.warning(f"[whitelist] DOB write-back failed for {wb['reg_no']}: {e}")

    return merged


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
    log.info(f"[sync] {rollno} – DOB resolved, logging in to eCampus")

    # 2. Sync + persist
    try:
        att_data, cgpa_data, ca_data = _sync_single_rollno(rollno, dob)
    except Exception as exc:
        log.error(f"[sync] Login/sync failed for {rollno}: {exc}")
        raise HTTPException(status_code=502, detail=f"eCampus sync failed: {exc}")

    log.info(f"[sync] {rollno} – data stored ✔")

    synced_at = datetime.utcnow().isoformat()
    return {
        "ok": True,
        "rollno": rollno,
        "synced_at": synced_at,
        "attendance_summary": att_data["summary"],
        "cgpa": cgpa_data.get("cgpa"),
        "ca_subjects_count": len(ca_data.get("subjects", [])),
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


@app.get("/api/ecampus/ca-marks")
def get_ca_marks(
    rollno: str = Query(...),
    x_api_secret: str | None = Header(None),
):
    """Returns the latest cached CA marks data from Supabase.
    If CA marks have not been published yet by the institution the
    subjects list will be empty – that is normal behaviour.
    """
    _check_secret(x_api_secret)
    row = _read_ca_marks(rollno)
    if not row:
        raise HTTPException(
            status_code=404,
            detail="No CA marks data found. Please sync first.",
        )
    return {"ok": True, "rollno": rollno, **row}


@app.post("/api/ecampus/sync-all")
def sync_all_users(
    x_api_secret: str | None = Header(None),
    authorization: str | None = Header(None),
):
    """
    Syncs eCampus data for ALL students in the whitelist that have a DOB set.
    Useful for a scheduled cron job (run nightly).  Returns a summary.
    """
    _check_secret(x_api_secret)
    _require_placement_rep(authorization)

    students = _get_whitelist_students_with_dob()
    log.info(f"[sync-all] Found {len(students)} students with DOB")

    # Total whitelist count (for reporting students missing DOB)
    all_whitelist = (
        _get_supabase().table("whitelist").select("reg_no", count="exact")
        .not_.is_("reg_no", "null").execute()
    )
    total_whitelist = all_whitelist.count or len(students)
    no_dob_count = total_whitelist - len(students)
    if no_dob_count > 0:
        log.warning(f"[sync-all] {no_dob_count} students in whitelist have no DOB – they will be skipped")

    success, failed = [], []
    for s in students:
        rollno = s["reg_no"]
        try:
            dob = _parse_dob_value(s["dob"])
            log.info(f"[sync-all] syncing {rollno} (DOB={dob} → pwd={_dob_to_password(dob)})")
            _sync_single_rollno(rollno, dob)
            success.append(rollno)
            log.info(f"[sync-all] ✔ {rollno}")
        except Exception as exc:
            error_msg = str(exc)
            # Classify the error for easier debugging
            if "login" in error_msg.lower() or "Attendance table not found" in error_msg:
                error_type = "login_failed"
            elif "timeout" in error_msg.lower() or "ConnectionError" in error_msg:
                error_type = "network_error"
            else:
                error_type = "other"
            failed.append({"rollno": rollno, "error": error_msg, "error_type": error_type})
            log.error(f"[sync-all] ✗ {rollno} [{error_type}]: {exc}")

    return {
        "ok": True,
        "total_whitelist": total_whitelist,
        "students_with_dob": len(students),
        "no_dob_skipped": no_dob_count,
        "success_count": len(success),
        "failed_count": len(failed),
        "failed": failed,
        "synced_at": datetime.utcnow().isoformat(),
    }


@app.get("/api/ecampus/sync-all/status")
def sync_all_status(
    x_api_secret: str | None = Header(None),
    authorization: str | None = Header(None),
):
    """Returns bulk-sync coverage info so placement rep can verify DB writes."""
    _check_secret(x_api_secret)
    _require_placement_rep(authorization)

    students = _get_whitelist_students_with_dob()
    expected_regnos = {s["reg_no"] for s in students if s.get("reg_no")}

    att_rows = (
        _get_supabase().table("ecampus_attendance")
        .select("reg_no, synced_at")
        .execute()
    ).data or []
    cgpa_rows = (
        _get_supabase().table("ecampus_cgpa")
        .select("reg_no, synced_at")
        .execute()
    ).data or []

    att_regnos = {r.get("reg_no") for r in att_rows if r.get("reg_no")}
    cgpa_regnos = {r.get("reg_no") for r in cgpa_rows if r.get("reg_no")}

    missing_attendance = sorted(list(expected_regnos - att_regnos))
    missing_cgpa = sorted(list(expected_regnos - cgpa_regnos))

    latest_att = max((r.get("synced_at", "") for r in att_rows), default="")
    latest_cgpa = max((r.get("synced_at", "") for r in cgpa_rows), default="")

    return {
        "ok": True,
        "expected_students": len(expected_regnos),
        "attendance_rows": len(att_rows),
        "cgpa_rows": len(cgpa_rows),
        "latest_attendance_sync": latest_att or None,
        "latest_cgpa_sync": latest_cgpa or None,
        "missing_attendance_count": len(missing_attendance),
        "missing_cgpa_count": len(missing_cgpa),
        "missing_attendance": missing_attendance[:50],
        "missing_cgpa": missing_cgpa[:50],
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("ecampus_api:app", host="0.0.0.0", port=8000, reload=True)
