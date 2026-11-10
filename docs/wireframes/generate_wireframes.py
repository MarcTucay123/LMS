from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).resolve().parent


class SVG:
    def __init__(self, title: str, width: int = 1440, height: int = 900):
        self.title = title
        self.width = width
        self.height = height
        self.parts = [
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">',
            f'<title>{escape(title)}</title>',
            '<rect width="100%" height="100%" fill="#f4f4f3"/>',
            '<style>text{font-family:Arial,sans-serif;fill:#686868}.title{font-size:24px;font-weight:700;fill:#555}.h2{font-size:17px;font-weight:700;fill:#606060}.label{font-size:12px;font-weight:700;fill:#777}.small{font-size:11px;fill:#888}.tiny{font-size:9px;fill:#999}.button{font-size:12px;font-weight:700;fill:#fff}.nav{font-size:12px;fill:#777}.active{font-weight:700;fill:#555}</style>',
        ]

    def rect(self, x, y, w, h, fill="#fff", stroke="#cfcfcf", radius=8, sw=1):
        self.parts.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>')

    def line(self, x1, y1, x2, y2, stroke="#d1d1d1", sw=1):
        self.parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{stroke}" stroke-width="{sw}"/>')

    def text(self, x, y, value, cls="small", anchor="start"):
        self.parts.append(f'<text x="{x}" y="{y}" class="{cls}" text-anchor="{anchor}">{escape(str(value))}</text>')

    def circle(self, cx, cy, r, fill="#ddd", stroke="#c8c8c8"):
        self.parts.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}" stroke="{stroke}"/>')

    def input(self, x, y, w, label="", placeholder=""):
        if label:
            self.text(x, y - 7, label, "label")
        self.rect(x, y, w, 42, "#fafafa", "#c9c9c9", 5)
        if placeholder:
            self.text(x + 12, y + 25, placeholder, "small")

    def button(self, x, y, w, label, secondary=False):
        fill = "#fff" if secondary else "#8b8b8b"
        stroke = "#bcbcbc" if secondary else "#8b8b8b"
        self.rect(x, y, w, 40, fill, stroke, 5)
        self.text(x + w / 2, y + 25, label, "label" if secondary else "button", "middle")

    def lines(self, x, y, widths, gap=12, height=5):
        for index, width in enumerate(widths):
            self.rect(x, y + index * gap, width, height, "#c8c8c8", "none", 2)

    def save(self, filename: str):
        self.parts.append('</svg>')
        (OUT / filename).write_text('\n'.join(self.parts), encoding='utf-8')


def auth_shell(title, subtitle, height=900, card_height=590):
    s = SVG(title, 900, height)
    s.rect(0, 0, 900, height, "#e9e9e7", "none", 0)
    s.circle(450, 65, 25, "#d0d0d0")
    s.text(450, 108, "ADFC OneCampus", "title", "middle")
    s.text(450, 130, "Learning Management System", "small", "middle")
    top = 155
    s.rect(210, top, 480, card_height, "#fff", "#c8c8c8", 12)
    s.text(250, top + 48, title, "title")
    s.text(250, top + 72, subtitle, "small")
    return s, top


def app_shell(title, subtitle, active="Dashboard"):
    s = SVG(title)
    s.rect(0, 0, 245, 900, "#f8f8f7", "#c8c8c8", 0)
    s.rect(245, 0, 1195, 82, "#fff", "#c8c8c8", 0)
    s.circle(38, 40, 19, "#d0d0d0")
    s.text(68, 36, "ADFC OneCampus", "h2")
    s.text(68, 54, "Learning Management System", "tiny")
    nav = ["Dashboard", "My Classes", "Materials", "Assignments", "Quizzes", "Discussions", "Announcements", "Progress & Reports"]
    y = 105
    for item in nav:
        if item == active:
            s.rect(18, y - 23, 209, 38, "#e5e5e5", "none", 5)
        s.circle(38, y - 4, 6, "#c5c5c5", "none")
        s.text(55, y, item, "active" if item == active else "nav")
        y += 45
    s.text(24, 505, "ADMINISTRATION", "tiny")
    for item in ["Registration Approvals", "User Accounts", "Class Offerings", "OneCampus Sync"]:
        if item == active:
            s.rect(18, y - 23, 209, 38, "#e5e5e5", "none", 5)
        s.circle(38, y - 4, 6, "#c5c5c5", "none")
        s.text(55, y, item, "active" if item == active else "nav")
        y += 42
    s.rect(18, 810, 209, 68, "#f0f0f0", "#d2d2d2", 8)
    s.circle(48, 844, 18, "#d0d0d0")
    s.lines(76, 828, [90, 122, 62], 13, 5)
    s.text(285, 35, title, "title")
    s.text(285, 58, subtitle, "small")
    s.circle(1264, 39, 18, "#d0d0d0")
    s.lines(1292, 28, [74, 50], 14, 5)
    s.button(1368, 21, 54, "Exit", True)
    return s


def page_heading(s, eyebrow, title, description, action=None):
    s.rect(280, 112, 1125, 105, "#fff", "#d0d0d0", 10)
    s.text(310, 138, eyebrow.upper(), "tiny")
    s.text(310, 169, title, "title")
    s.text(310, 194, description, "small")
    if action:
        s.button(1228, 143, 140, action)


def login():
    s, top = auth_shell("Sign in", "Choose your portal and access your LMS account.")
    s.rect(250, top + 100, 400, 46, "#f3f3f3", "#d0d0d0", 6)
    for x, label in [(255, "Student"), (385, "Instructor"), (515, "Administrator")]:
        active = label == "Student"
        s.rect(x, top + 105, 125, 36, "#ddd" if active else "#fafafa", "#ccc", 5)
        s.text(x + 62, top + 128, label, "active" if active else "small", "middle")
    s.text(250, top + 188, "Student sign in", "h2")
    s.text(250, top + 211, "Access classes, activities, and progress.", "small")
    s.input(250, top + 250, 400, "Email address", "student@example.com")
    s.input(250, top + 330, 400, "Password", "••••••••")
    s.text(650, top + 392, "Forgot password?", "small", "end")
    s.button(250, top + 420, 400, "Sign in as Student")
    s.line(250, top + 485, 650, top + 485)
    s.text(450, top + 520, "Don't have an account? Register as Student", "small", "middle")
    s.save("01-login.svg")


def simple_registration(role, filename):
    title = f"{role} registration"
    subtitle = "Submit an application for administrator approval."
    s, top = auth_shell(title, subtitle, 980, 755)
    s.text(250, top + 110, "Personal name", "h2")
    s.input(250, top + 145, 190, "First name", "First name")
    s.input(460, top + 145, 190, "Middle name", "Optional")
    s.input(250, top + 220, 190, "Last name", "Last name")
    s.input(460, top + 220, 190, "Suffix", "Optional")
    s.input(250, top + 305, 400, "Email address", "name@example.com")
    s.input(250, top + 385, 400, "Create password", "••••••••")
    s.input(250, top + 465, 400, "Confirm password", "••••••••")
    s.lines(250, top + 535, [360, 300], 12, 4)
    s.button(250, top + 575, 400, f"Register as {role}")
    s.text(450, top + 650, f"Already registered? Back to {role.lower()} sign in", "small", "middle")
    s.save(filename)


def student_registration():
    s, top = auth_shell("Student registration", "Select your academic term and enrolled subjects.", 1350, 1120)
    s.input(250, top + 105, 190, "Student ID", "2026-0001")
    s.input(460, top + 105, 190, "Class code", "1234")
    s.input(250, top + 180, 190, "First name", "First name")
    s.input(460, top + 180, 190, "Middle name", "Optional")
    s.input(250, top + 255, 190, "Last name", "Last name")
    s.input(460, top + 255, 190, "Email", "student@example.com")
    for x, y, label, value in [
        (250, top + 340, "Program", "BSIT  ▼"), (460, top + 340, "Year level", "1  ▼"),
        (250, top + 415, "Block", "A  ▼"), (460, top + 415, "Semester", "First Semester  ▼"),
        (250, top + 490, "Academic year", "2026-2027  ▼")]:
        s.input(x, y, 190 if x == 250 or y != top + 490 else 400, label, value)
    s.text(250, top + 580, "Subjects Enrolled", "label")
    s.text(650, top + 580, "Select all  |  Clear", "small", "end")
    s.rect(250, top + 595, 400, 190, "#fafafa", "#c9c9c9", 6)
    for index, (code, name) in enumerate([("IT 101", "Introduction to Computing"), ("ENG 102", "Communication Skills"), ("MATH 103", "College Mathematics"), ("IT 104", "Programming Fundamentals")]):
        x = 265 + (index % 2) * 190
        y = top + 615 + (index // 2) * 78
        s.rect(x, y, 174, 60, "#fff", "#d3d3d3", 5)
        s.rect(x + 10, y + 20, 12, 12, "#eee", "#aaa", 2)
        s.text(x + 32, y + 25, code, "label")
        s.text(x + 32, y + 43, name, "tiny")
    s.input(250, top + 825, 190, "Password", "••••••••")
    s.input(460, top + 825, 190, "Confirm password", "••••••••")
    s.rect(250, top + 900, 12, 12, "#eee", "#aaa", 2)
    s.text(270, top + 910, "I agree to the Terms and Privacy Policy", "small")
    s.button(250, top + 945, 400, "Register Account")
    s.save("02-student-registration.svg")


def recovery_page(reset=False):
    title = "Reset your password" if reset else "Forgot password?"
    subtitle = "Choose a new secure password." if reset else "Receive a secure password-reset link."
    s, top = auth_shell(title, subtitle, 800, 500)
    s.text(250, top + 105, "← Back to sign in", "small")
    if reset:
        s.input(250, top + 160, 400, "New password", "••••••••")
        s.input(250, top + 240, 400, "Confirm new password", "••••••••")
        s.lines(250, top + 305, [340, 275], 11, 4)
        s.button(250, top + 350, 400, "Reset password")
        s.save("06-reset-password.svg")
    else:
        s.input(250, top + 175, 400, "Email address", "registered@example.com")
        s.button(250, top + 255, 400, "Send reset link")
        s.rect(250, top + 325, 400, 80, "#f4f4f4", "#d0d0d0", 6)
        s.text(270, top + 350, "Confirmation message appears here", "label")
        s.lines(270, top + 368, [330, 280], 11, 4)
        s.save("05-forgot-password.svg")


def dashboard():
    s = app_shell("Dashboard", "Your learning overview and active classes", "Dashboard")
    s.rect(280, 112, 1125, 180, "#dedede", "#c5c5c5", 12)
    s.circle(330, 165, 24, "#c4c4c4")
    s.text(370, 158, "Good morning, User!", "title")
    s.text(370, 184, "Welcome to your ADFC learning space.", "small")
    s.lines(370, 206, [475, 405], 12, 5)
    s.text(1365, 160, "09:42:16 AM", "h2", "end")
    s.text(1365, 184, "Monday, November 2, 2026", "small", "end")
    for index, label in enumerate(["Active Classes", "Academic Year", "Account Status"]):
        x = 280 + index * 380
        s.rect(x, 315, 350, 115, "#fff", "#d0d0d0", 9)
        s.text(x + 22, 345, label, "label")
        s.text(x + 22, 382, ["3", "2026–2027", "Active"][index], "title")
        s.circle(x + 305, 370, 22, "#ddd")
    s.text(280, 478, "My Classes", "title")
    s.text(280, 500, "Open a class to access its learning area.", "small")
    for index in range(3):
        x = 280 + index * 380
        s.rect(x, 530, 350, 280, "#fff", "#ccc", 10)
        s.rect(x, 530, 350, 75, "#d8d8d8", "none", 10)
        s.text(x + 22, 640, ["IT 101", "ENG 102", "MATH 103"][index], "label")
        s.lines(x + 22, 658, [250, 205], 14, 6)
        s.rect(x + 22, 705, 145, 45, "#f3f3f3", "#ddd", 5)
        s.rect(x + 183, 705, 145, 45, "#f3f3f3", "#ddd", 5)
        s.lines(x + 22, 775, [185, 125], 12, 4)
        s.circle(x + 310, 782, 16, "#ccc")
    s.save("07-dashboard.svg")


def classes_page():
    s = app_shell("My Classes", "Authorized assigned or enrolled class workspaces", "My Classes")
    page_heading(s, "Course access", "Classes you are enrolled in", "Open an authorized class to access its complete learning workspace.")
    for index in range(6):
        col, row = index % 3, index // 3
        x, y = 280 + col * 380, 250 + row * 285
        s.rect(x, y, 350, 250, "#fff", "#ccc", 10)
        s.rect(x, y, 350, 62, "#ddd", "none", 10)
        s.circle(x + 30, y + 31, 16, "#c4c4c4")
        s.text(x + 22, y + 95, f"SUBJ {index + 101}", "label")
        s.lines(x + 22, y + 112, [260, 210], 14, 6)
        s.rect(x + 22, y + 155, 145, 42, "#f4f4f4", "#ddd", 5)
        s.rect(x + 183, y + 155, 145, 42, "#f4f4f4", "#ddd", 5)
        s.lines(x + 22, y + 218, [180], 10, 4)
        s.circle(x + 310, y + 220, 15, "#ccc")
    s.save("08-classes.svg")


def workspace_content(s, kind):
    if kind == "Materials":
        for i in range(4):
            y = 355 + i * 105
            s.rect(310, y, 1065, 82, "#fff", "#d0d0d0", 7)
            s.circle(345, y + 41, 17, "#ddd")
            s.lines(375, y + 20, [260, 520, 135], 16, 5)
            s.button(1230, y + 21, 55, "Open", True)
            s.button(1295, y + 21, 55, "Del", True)
    elif kind == "Assignments":
        for i in range(3):
            y = 350 + i * 165
            s.rect(310, y, 1065, 140, "#fff", "#d0d0d0", 7)
            s.text(335, y + 32, f"Assignment {i + 1}", "h2")
            s.rect(1210, y + 15, 130, 26, "#eee", "#ccc", 13)
            s.lines(335, y + 52, [720, 620, 245], 15, 5)
            s.text(335, y + 116, "Due date · 100 points", "small")
            s.button(1190, y + 85, 150, "View / Submit", True)
    elif kind == "Quizzes":
        s.rect(310, 350, 280, 430, "#fff", "#d0d0d0", 7)
        for i in range(5):
            s.rect(330, 375 + i * 70, 240, 52, "#eee" if i == 0 else "#fafafa", "#d5d5d5", 5)
            s.lines(345, 390 + i * 70, [140, 92], 13, 4)
        s.rect(615, 350, 760, 430, "#fff", "#d0d0d0", 7)
        s.text(645, 390, "Selected Quiz", "h2")
        s.lines(645, 410, [590, 510], 14, 5)
        for i in range(3):
            s.rect(645, 460 + i * 78, 690, 62, "#f6f6f6", "#ddd", 5)
            s.lines(665, 478 + i * 78, [420, 310], 14, 4)
        s.button(1125, 720, 210, "Submit Quiz")
    elif kind == "Discussions":
        s.rect(310, 350, 300, 430, "#fff", "#d0d0d0", 7)
        s.button(335, 375, 250, "+ New Topic", True)
        for i in range(5):
            s.rect(335, 435 + i * 60, 250, 45, "#eee" if i == 0 else "#fafafa", "#ddd", 5)
            s.lines(350, 447 + i * 60, [155, 100], 12, 4)
        s.rect(635, 350, 740, 430, "#fff", "#d0d0d0", 7)
        s.text(665, 390, "Discussion Topic", "h2")
        s.lines(665, 412, [600, 520, 450], 14, 5)
        s.line(665, 470, 1345, 470)
        for i in range(3):
            s.circle(685, 510 + i * 68, 14, "#ddd")
            s.lines(710, 496 + i * 68, [150, 500, 405], 13, 4)
        s.input(665, 710, 560, "", "Write a reply...")
        s.button(1240, 710, 105, "Send")
    elif kind == "Announcements":
        for i in range(4):
            y = 350 + i * 108
            s.rect(310, y, 1065, 85, "#fff", "#d0d0d0", 7)
            s.circle(345, y + 40, 17, "#ddd")
            s.text(375, y + 28, f"Announcement title {i + 1}", "h2")
            s.lines(375, y + 43, [680, 590], 14, 5)
            s.text(1325, y + 72, "Date", "tiny", "end")
    elif kind == "Progress & Reports":
        for i, label in enumerate(["Overall Score", "Points Earned", "Completed"]):
            x = 310 + i * 355
            s.rect(x, 350, 325, 115, "#fff", "#d0d0d0", 7)
            s.text(x + 22, 380, label, "label")
            s.text(x + 22, 425, ["90.0%", "180 / 200", "8 / 10"][i], "title")
            s.circle(x + 282, 408, 20, "#ddd")
        s.rect(310, 495, 1065, 285, "#fff", "#d0d0d0", 7)
        headers = ["Activity", "Type", "Status", "Score", "Feedback"]
        positions = [335, 700, 850, 1000, 1120]
        for x, label in zip(positions, headers):
            s.text(x, 530, label, "label")
        s.line(330, 545, 1355, 545)
        for row in range(5):
            y = 578 + row * 38
            s.lines(335, y, [280], 10, 4)
            for x in positions[1:]:
                s.rect(x, y - 4, 90 if x != 1120 else 170, 8, "#d0d0d0", "none", 2)


def classroom():
    s = app_shell("Classroom", "Learning resources and class activities", "My Classes")
    s.text(280, 120, "← Back to dashboard", "small")
    s.rect(280, 145, 1125, 120, "#ddd", "#c8c8c8", 10)
    s.text(310, 180, "IT 101", "label")
    s.text(310, 212, "Introduction to Computing", "title")
    s.text(310, 240, "Section BSIT-1A · First Semester · Instructor Name", "small")
    tabs = ["Materials", "Assignments", "Quizzes", "Discussions", "Announcements", "Progress"]
    x = 300
    for tab in tabs:
        s.text(x, 305, tab, "active" if tab == "Materials" else "small")
        x += 160
    s.line(280, 320, 1405, 320)
    s.text(310, 350, "Learning Materials", "title")
    s.text(310, 374, "Files and links shared with this class.", "small")
    s.button(1215, 340, 160, "+ Add Material")
    for i in range(4):
        y = 410 + i * 95
        s.rect(310, y, 1065, 72, "#fff", "#d0d0d0", 7)
        s.circle(345, y + 36, 16, "#ddd")
        s.lines(375, y + 18, [260, 520, 135], 15, 5)
        s.button(1280, y + 16, 70, "Open", True)
    s.save("09-classroom.svg")


def workspace(kind, filename, active):
    s = app_shell(kind, f"Class workspace for {kind.lower()}", active)
    s.rect(280, 112, 1125, 155, "#fff", "#d0d0d0", 10)
    s.text(310, 138, "CLASS WORKSPACE", "tiny")
    s.text(310, 174, kind, "title")
    s.text(310, 200, f"View and manage class {kind.lower()}.", "small")
    s.input(1030, 155, 335, "Selected class", "IT 101 — BSIT-1A  ▼")
    s.rect(280, 290, 1125, 520, "#f9f9f9", "#d0d0d0", 9)
    s.text(310, 325, kind, "title")
    action = {"Materials": "+ Add Material", "Assignments": "+ New Assignment", "Quizzes": "+ New Quiz", "Discussions": "+ New Topic", "Announcements": "+ Announcement"}.get(kind)
    if action:
        s.button(1200, 305, 170, action)
    workspace_content(s, kind)
    s.save(filename)


def admin_registrations():
    s = app_shell("Registration Approvals", "Approve applicants, generate IDs, and assign instructors", "Registration Approvals")
    page_heading(s, "Administration", "Registration approvals", "Review pending student, instructor, and administrator applications.")
    for i in range(2):
        y = 245 + i * 225
        s.rect(280, y, 1125, 195, "#fff", "#ccc", 9)
        s.circle(320, y + 38, 20, "#ddd")
        s.text(355, y + 33, ["Student Applicant", "Instructor Applicant"][i], "h2")
        s.text(355, y + 55, "applicant@example.com · Pending", "small")
        s.rect(1225, y + 18, 135, 28, "#eee", "#ccc", 14)
        s.text(1292, y + 37, ["STUDENT", "INSTRUCTOR"][i], "label", "middle")
        s.line(310, y + 75, 1375, y + 75)
        for c in range(4):
            x = 320 + c * 230
            s.text(x, y + 102, ["STUDENT ID", "PROGRAM / YEAR", "ACADEMIC TERM", "SELECTED SUBJECTS"][c], "tiny")
            s.lines(x, y + 115, [150, 115], 12, 4)
        if i == 1:
            s.rect(320, y + 145, 620, 28, "#f4f4f4", "#ddd", 4)
            s.text(335, y + 164, "□ IT 101   □ ENG 102   □ MATH 103", "small")
        s.button(1150, y + 135, 95, "Reject", True)
        s.button(1255, y + 135, 105, "Approve")
    s.text(280, 715, "Reviewed Applications", "h2")
    s.rect(280, 735, 1125, 110, "#fff", "#ccc", 7)
    for x, label in [(310, "Applicant"), (700, "Requested role"), (920, "Status"), (1120, "Reviewed")]:
        s.text(x, 765, label, "label")
    s.line(300, 780, 1385, 780)
    for x, w in [(310, 260), (700, 110), (920, 80), (1120, 190)]:
        s.rect(x, 805, w, 6, "#ccc", "none", 2)
    s.save("16-admin-registrations.svg")


def admin_users():
    s = app_shell("User Accounts", "Manage LMS access, roles, and account status", "User Accounts")
    page_heading(s, "Administration", "User accounts", "Review synchronized users and manage database-assigned roles.")
    s.input(280, 245, 540, "", "Search name, email, ID, role, or status")
    s.text(1405, 270, "24 accounts", "small", "end")
    s.rect(280, 315, 1125, 500, "#fff", "#ccc", 8)
    headers = [(310, "USER"), (720, "SCHOOL ID"), (900, "ROLE"), (1060, "STATUS"), (1240, "ACTION")]
    for x, label in headers:
        s.text(x, 350, label, "label")
    s.line(300, 365, 1385, 365)
    for row in range(7):
        y = 395 + row * 58
        s.circle(330, y + 15, 14, "#ddd")
        s.lines(355, y + 2, [235, 170], 14, 4)
        s.rect(720, y + 7, 120, 7, "#ccc", "none", 2)
        s.rect(900, y - 2, 125, 34, "#fafafa", "#ccc", 4)
        s.text(915, y + 19, "student  ▼", "small")
        s.rect(1060, y - 2, 125, 34, "#fafafa", "#ccc", 4)
        s.text(1075, y + 19, "active  ▼", "small")
        s.button(1240, y - 5, 95, "Save", True)
        s.line(300, y + 44, 1385, y + 44)
    s.save("17-admin-users.svg")


def admin_classes():
    s = app_shell("Class Offerings", "Manage subjects, instructors, and academic offerings", "Class Offerings")
    page_heading(s, "Administration", "Class offerings", "Create and maintain LMS class offerings.", "+ New Class")
    for i in range(6):
        col, row = i % 3, i // 3
        x, y = 280 + col * 380, 250 + row * 270
        s.rect(x, y, 350, 235, "#fff", "#ccc", 9)
        s.text(x + 22, y + 32, f"SUBJ {101 + i}", "label")
        s.rect(x + 260, y + 16, 68, 24, "#eee", "#ccc", 12)
        s.lines(x + 22, y + 52, [245, 190], 14, 6)
        for j, label in enumerate(["Section", "School year", "Semester", "Instructor"]):
            px = x + 22 + (j % 2) * 160
            py = y + 105 + (j // 2) * 48
            s.text(px, py, label, "tiny")
            s.rect(px, py + 8, 110, 5, "#ccc", "none", 2)
        s.button(x + 22, y + 185, 306, "Edit Offering", True)
    s.save("18-admin-classes.svg")


def admin_sync():
    s = app_shell("OneCampus Sync", "Import institutional records and review sync history", "OneCampus Sync")
    page_heading(s, "OneCampus integration", "Synchronization", "Import users, subjects, classes, and enrollments.", "Sync Now")
    s.rect(280, 245, 1125, 72, "#eee", "#ccc", 7)
    s.text(310, 272, "Mock fallback is enabled", "label")
    s.text(310, 296, "When the API URL is empty, repository fixtures are imported automatically.", "small")
    s.rect(280, 345, 1125, 460, "#fff", "#ccc", 8)
    headers = [(310, "STARTED"), (520, "SOURCE"), (700, "STATUS"), (840, "RECORDS"), (1110, "MESSAGE")]
    for x, label in headers:
        s.text(x, 380, label, "label")
    s.line(300, 395, 1385, 395)
    for row in range(7):
        y = 430 + row * 52
        s.text(310, y, "Nov 2, 2026 09:30", "small")
        s.text(520, y, "OneCampus API" if row % 2 == 0 else "Mock fixtures", "small")
        s.rect(700, y - 16, 78, 24, "#eee", "#ccc", 12)
        s.text(739, y, "success", "tiny", "middle")
        s.lines(840, y - 9, [190, 150], 12, 4)
        s.lines(1110, y - 9, [235, 190], 12, 4)
        s.line(300, y + 20, 1385, y + 20)
    s.save("19-admin-sync.svg")


def not_found():
    s = SVG("Page Not Found", 900, 650)
    s.rect(0, 0, 900, 650, "#f3f3f3", "none", 0)
    s.text(450, 230, "404", "title", "middle")
    s.text(450, 280, "Page not found", "title", "middle")
    s.text(450, 315, "The page you requested is unavailable.", "small", "middle")
    s.button(335, 360, 230, "Return to Dashboard")
    s.save("20-not-found.svg")


def main():
    login()
    student_registration()
    simple_registration("Instructor", "03-instructor-registration.svg")
    simple_registration("Administrator", "04-admin-registration.svg")
    recovery_page(False)
    recovery_page(True)
    dashboard()
    classes_page()
    classroom()
    workspace("Materials", "10-workspace-materials.svg", "Materials")
    workspace("Assignments", "11-workspace-assignments.svg", "Assignments")
    workspace("Quizzes", "12-workspace-quizzes.svg", "Quizzes")
    workspace("Discussions", "13-workspace-discussions.svg", "Discussions")
    workspace("Announcements", "14-workspace-announcements.svg", "Announcements")
    workspace("Progress & Reports", "15-workspace-progress.svg", "Progress & Reports")
    admin_registrations()
    admin_users()
    admin_classes()
    admin_sync()
    not_found()
    print(f"Generated 20 wireframes in {OUT}")


if __name__ == "__main__":
    main()