import math
import requests
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

def gradeMap(grade):
    grade_map = {
        "O": 10, "A+": 9, "A": 8, "B+": 7, 
        "B": 6, "C+": 5, "C": 4, "RA": 0, "SA": 0, "W": 0
    }
    return grade_map.get(grade.strip().upper(), 0)

def return_attendance(username, pwd):
    try:
        session = requests.Session()
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }

        # Login
        login_url = "https://ecampus.psgtech.ac.in/studzone2/"
        r = session.get(login_url, headers=headers)
        soup = BeautifulSoup(r.text, 'html.parser')

        viewstate = soup.select("#__VIEWSTATE")[0]["value"]
        eventvalidation = soup.select("#__EVENTVALIDATION")[0]["value"]
        viewstategen = soup.select("#__VIEWSTATEGENERATOR")[0]["value"]

        payload = {
            "__VIEWSTATE": viewstate,
            "__VIEWSTATEGENERATOR": viewstategen,
            "__EVENTVALIDATION": eventvalidation,
            "txtusercheck": username,
            "txtpwdcheck": pwd,
            "abcd3": "Login"
        }

        session.post(login_url, data=payload, headers=headers)

        # Get attendance
        attendance_url = "https://ecampus.psgtech.ac.in/studzone2/AttWfPercView.aspx"
        page = session.get(attendance_url, headers=headers)
        soup = BeautifulSoup(page.text, 'html.parser')

        table = soup.find("table", {"class": "cssbody"})
        if not table:
            return "Attendance data is updatng try again later or invalid password"

        data = []
        for row in table.find_all("tr"):
            cols = [ele.text.strip() for ele in row.find_all("td")]
            data.append([ele for ele in cols if ele])

        return data, session

    except Exception as e:
        return f"Error: {str(e)}"

def get_course_plan(session):
    """Get course plan with course titles"""
    try:
        course_url = "https://ecampus.psgtech.ac.in/studzone2/AttWfStudTimtab.aspx"
        page = session.get(course_url)
        soup = BeautifulSoup(page.text, 'html.parser')

        table = soup.find("table", {"id": "TbCourDesc"})
        if not table:
            return {}

        course_mapping = {}
        for row in table.find_all("tr")[1:]:  # Skip header
            cols = [ele.text.strip() for ele in row.find_all("td")]
            if len(cols) >= 2:
                course_mapping[cols[0]] = cols[1]

        return course_mapping
    except:
        return {}

def data_json(data, course_plan=None):
    response = []
    for item in data[1:]:
        if len(item) < 10:
            continue

        temp = {
            "name": item[0],
            "course_title": course_plan.get(item[0], item[0]) if course_plan else item[0],
            "total_hours": int(item[1]),
            "exception_hour": int(item[2]),
            "total_present": int(item[4]),
            "percentage_of_attendance": float(item[5]),
            "attendance_from": item[8],
            "attendance_to": item[9]
        }

        if temp['percentage_of_attendance'] < 75:
            temp['class_to_attend'] = math.ceil(
                (0.75 * temp['total_hours'] - temp['total_present']) / 0.25
            )
        else:
            temp['class_to_bunk'] = math.floor(
                (temp['total_present'] - 0.75 * temp['total_hours']) / 0.75
            )

        response.append(temp)
    return response

def return_cgpa(session):
    try:
        # Get results
        results_url = "https://ecampus.psgtech.ac.in/studzone2/FrmEpsStudResult.aspx"
        page = session.get(results_url)
        soup = BeautifulSoup(page.text, 'html.parser')

        table = soup.find("table", {"id": "DgResult"})
        if not table:
            return {"error": "No results found"}

        # Process results
        data = []
        for row in table.find_all("tr")[1:]:  # Skip header
            cols = [ele.text.strip() for ele in row.find_all("td")]
            if len(cols) >= 6:  # Ensure valid row
                data.append({
                    "semester": cols[0],
                    "code": cols[1],
                    "title": cols[2],
                    "credits": int(cols[3]),
                    "grade": cols[4].split()[-1],  # Get last part
                    "result": cols[5]
                })

        # Calculate CGPA
        total_points = 0
        total_credits = 0
        latest_sem = ""

        for course in data:
            if course["credits"] > 0 and course["grade"] in ["O","A+","A","B+","B","C+","C"]:
                total_points += course["credits"] * gradeMap(course["grade"])
                total_credits += course["credits"]
                if course["semester"] > latest_sem:
                    latest_sem = course["semester"]

        cgpa = total_points / total_credits if total_credits > 0 else 0

        return {
            "lastest_sem": latest_sem,
            "latest_sem_cgpa": round(cgpa, 3),
            "total_cgpa": round(cgpa, 3),
            "total_semesters": len(set(course["semester"] for course in data)),
            "courses": data
        }

    except Exception as e:
        return {"error": str(e)}