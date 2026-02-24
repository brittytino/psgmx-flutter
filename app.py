import os
import math
from datetime import datetime
import xml.etree.ElementTree as ET
from flask import Flask, render_template, request, jsonify, session as flask_session, send_from_directory, redirect, Response
from bunker_mod import return_attendance, data_json, return_cgpa, get_course_plan

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'psg-bunker-secret-key-change-in-production')

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/login', methods=['POST'])
def login():
    # Handle both form and JSON data
    if request.is_json:
        rollno = request.json.get('rollno')
        password = request.json.get('password')
    else:
        rollno = request.form.get('rollno')
        password = request.form.get('password')

    if not rollno or not password:
        if request.is_json:
            return jsonify({"ok": False, "message": "Roll number and password are required"})
        else:
            return render_template("index.html", error="Roll number and password are required")

    result = return_attendance(rollno, password)

    if isinstance(result, str):
        if request.is_json:
            return jsonify({"ok": False, "message": result})
        else:
            return render_template("index.html", error=result)

    attendance_raw, session = result

    # Get real course plan data with course titles
    course_plan = get_course_plan(session)

    # Process attendance data with real course names from courseplan
    attendance_data = data_json(attendance_raw, course_plan)
    cgpa_data = return_cgpa(session)

    # Store data in Flask session for API endpoints
    flask_session['attendance_data'] = attendance_data
    flask_session['cgpa_data'] = cgpa_data
    flask_session['course_plan'] = course_plan
    flask_session['rollno'] = rollno

    if request.is_json:
        return jsonify({"ok": True})
    else:
        return render_template("dashboard.html",
                             rollno=rollno,
                             attendance=attendance_data,
                             cgpa=cgpa_data)

@app.route('/attendance')
def get_attendance():
    """API endpoint for attendance data with course titles"""
    attendance_data = flask_session.get('attendance_data', [])

    if not attendance_data:
        return jsonify({"error": "No attendance data available"})

    # Calculate overall statistics
    total_hours = sum(subject['total_hours'] for subject in attendance_data)
    total_present = sum(subject['total_present'] for subject in attendance_data)
    overall_percentage = (total_present / total_hours * 100) if total_hours > 0 else 0

    # Calculate bunkable/need days for 75% threshold
    if overall_percentage < 75:
        need_days = math.ceil((0.75 * total_hours - total_present) / 0.25)
        bunkable_days = 0
    else:
        need_days = 0
        bunkable_days = int((total_present - 0.75 * total_hours) / 0.75)

    # Include course titles in response
    subjects_with_titles = []
    for subject in attendance_data:
        subject_with_title = subject.copy()
        subject_with_title['display_name'] = subject.get('course_title', subject.get('name', subject.get('original_name', 'Unknown Course')))
        subjects_with_titles.append(subject_with_title)

    return jsonify({
        "subjects": subjects_with_titles,
        "total_days": total_hours,
        "attended_days": total_present,
        "percentage": overall_percentage,
        "need_days": need_days,
        "bunkable_days": bunkable_days
    })

@app.route('/cgpa')
def get_cgpa():
    """API endpoint for CGPA data"""
    cgpa_data = flask_session.get('cgpa_data', {})
    return jsonify(cgpa_data)

@app.route('/courses')
def get_courses():
    """API endpoint to get course mapping"""
    course_plan = flask_session.get('course_plan', {})
    return jsonify(course_plan)

@app.route('/dashboard')
def dashboard():
    """Dashboard page route with course titles"""
    if 'rollno' not in flask_session:
        return redirect('/')

    return render_template("dashboard.html",
                         rollno=flask_session['rollno'],
                         attendance=flask_session.get('attendance_data', []),
                         cgpa=flask_session.get('cgpa_data', {}))

@app.route('/favicon.ico')
def favicon():
    return send_from_directory('static', 'favicon.ico')

@app.route('/download/app')
def download_apk():
    """Dedicated route for APK download with proper MIME type and headers"""
    response = send_from_directory(
        'static',
        'PSGBunker.apk',
        mimetype='application/vnd.android.package-archive',
        as_attachment=True,
        download_name='PSGBunker.apk'
    )
    # Add headers to prevent caching issues and ensure proper download
    response.headers['Content-Disposition'] = 'attachment; filename=PSGBunker.apk'
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    return response

@app.route('/sitemap.xml')
def sitemap():
    """Generate dynamic sitemap for SEO"""
    base_url = request.url_root.rstrip('/')
    
    # Create sitemap XML structure
    urlset = ET.Element("urlset")
    urlset.set("xmlns", "http://www.sitemaps.org/schemas/sitemap/0.9")
    
    # Define pages to index
    sitemap_pages = [
        {
            'url': '/',
            'priority': '1.0',
            'changefreq': 'daily',
            'lastmod': datetime.now().strftime('%Y-%m-%d')
        }
    ]
    
    # Build XML structure
    for page_info in sitemap_pages:
        url_elem = ET.SubElement(urlset, "url")
        
        loc_elem = ET.SubElement(url_elem, "loc")
        loc_elem.text = f"{base_url}{page_info['url']}"
        
        lastmod_elem = ET.SubElement(url_elem, "lastmod")
        lastmod_elem.text = page_info['lastmod']
        
        changefreq_elem = ET.SubElement(url_elem, "changefreq")
        changefreq_elem.text = page_info['changefreq']
        
        priority_elem = ET.SubElement(url_elem, "priority")
        priority_elem.text = page_info['priority']
    
    xml_content = ET.tostring(urlset, encoding='unicode', method='xml')
    xml_declaration = '<?xml version="1.0" encoding="UTF-8"?>\n'
    return Response(xml_declaration + xml_content, mimetype='application/xml')

@app.route('/robots.txt')
def robots():
    """Generate robots.txt for SEO"""
    base_url = request.url_root.rstrip('/')
    robots_content = f"""User-agent: *
Allow: /

# Block authenticated/API pages
Disallow: /dashboard
Disallow: /attendance
Disallow: /cgpa
Disallow: /courses

Sitemap: {base_url}/sitemap.xml
"""
    return Response(robots_content, mimetype='text/plain')

# Error handlers
@app.errorhandler(404)
def page_not_found(e):
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_server_error(e):
    return render_template('500.html'), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)