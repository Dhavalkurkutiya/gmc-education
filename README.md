# GMC Education Portal

> **Empowering every government school student in Gandhinagar with a reliable, simple, and fair digital learning experience — regardless of device, internet, or family literacy level.**

---

## Table of Contents

- [About the Project](#about-the-project)
- [Vision](#vision)
- [Who This Is For](#who-this-is-for)
- [Key Features](#key-features)
- [Project Status](#project-status)
- [Documentation Structure](#documentation-structure)
- [Product Design Process](#product-design-process)
- [Document Types](#document-types)
- [Constraints & Principles](#constraints--principles)
- [Success Metrics](#success-metrics)
- [Roadmap](#roadmap)
- [Out of Scope](#out-of-scope)
- [Contributing](#contributing)

---

## About the Project

**GMC Education Portal** is a digital platform designed for government schools in Gandhinagar Municipal Corporation (GMC). It enables students, teachers, parents, principals, and GMC administrators to interact with school data — attendance, assignments, notes, timetables, and reports — through a single unified platform.

The core design challenge: **this platform must work for users who have low-end Android phones, unreliable internet, and may be first-time digital tool users.**

---

## Vision

> To give every government school student in Gandhinagar a reliable, simple, and fair digital learning experience — regardless of their phone, their internet connection, or their family's literacy level.

### Why This Exists

| Problem | Who Suffers |
|---------|-------------|
| Homework and notes shared informally on WhatsApp — easy to miss | Students |
| Parents have no way to check attendance or marks without visiting school | Parents |
| Teachers maintain registers manually — slow, error-prone, easy to lose | Teachers |
| Principals have no real-time view of what is happening across classrooms | Principals |
| GMC has no data on which schools are performing, which are struggling | GMC Admins |
| Students with no internet at home fall behind completely | Students |

This is not a technology problem. **This is an equity problem.** A student with a working smartphone and home Wi-Fi gets more than a student without. This portal exists to close that gap.

---

## Who This Is For

| Role | What They Do |
|------|-------------|
| **Students** | View timetable, download notes offline, submit assignments |
| **Teachers** | Upload materials, mark attendance, grade assignments |
| **Parents** | Receive SMS alerts, view attendance and marks |
| **Principals** | Monitor school-level reports and classroom activity |
| **GMC Admins** | View district-wide performance data across all schools |

---

## Key Features

### Phase 1 — Pilot (10 Schools)
- Student login and timetable view
- Offline notes download
- Digital attendance marking by teachers
- SMS alerts to parents for attendance and marks
- Principal-level school reports

### Phase 2 — Expansion (6–18 Months, 50+ Schools)
- Full assignment workflow — upload, submit, grade
- Gujarati language across all screens
- Lightweight parent mobile app (works on 2G)

### Phase 3 — Scale (18 Months–3 Years, 100+ Schools)
- AI-based early warning system for at-risk students
- Integration with Gujarat state education board data
- Offline-first Progressive Web App (PWA)

---

## Project Status

This project is currently in the **Define Phase** of the product design process.

| Phase | Status | Notes |
|-------|--------|-------|
| Discovery | Complete | Field research, user interviews, pain point analysis |
| Define | Complete | All PRD documentation finalized |
| Design | Not Started | Wireframes, prototypes, high-fidelity designs |
| Development | Not Started | — |
| Testing | Not Started | — |
| Launch | Not Started | — |

### Documentation Completion

```
[x] 01-vision/vision.mdx
[x] 02-stakeholders/stakeholders.mdx
[x] 03-user-stories/          (5 files — student, teacher, parent, principal, admin)
[x] 04-features/              (5 files — overview, auth, student, teacher, parent+principal+admin)
[x] 05-edge-cases/            (5 files — auth, data-file, misc, network-offline, security-privacy)
[x] 06-security/security.mdx
[x] 07-offline-strategy/offline-strategy.mdx
[x] 08-notifications/notifications.mdx
[x] 09-testing/test-plan.mdx
[x] requirements/requirements.mdx
```

---

## Documentation Structure

```
gmc-education/
└── docs/
    ├── 01-vision/                    # Product vision, goals, success metrics
    ├── 02-stakeholders/              # Stakeholder map and responsibilities
    ├── 03-user-stories/              # User stories per role
    │   ├── student-stories.mdx
    │   ├── teacher-stories.mdx
    │   ├── parent-stories.mdx
    │   ├── principal-stories.mdx
    │   └── admin-stories.mdx
    ├── 04-features/                  # Feature specifications with priority
    │   ├── features-overview.mdx
    │   ├── auth-features.mdx
    │   ├── student-features.mdx
    │   ├── teacher-features.mdx
    │   └── parent-principal-admin-offline-features.mdx
    ├── 05-edge-cases/                # Error states, offline screens, edge cases
    ├── 06-security/                  # Security requirements (DPDP Act 2023)
    ├── 07-offline-strategy/          # Offline-first architecture decisions
    ├── 08-notifications/             # SMS and in-app notification specs
    ├── 09-testing/                   # Test cases, device testing, load testing
    ├── design/                       # Design system — colours, typography, components
    ├── requirements/                 # Technical specs for handoff to developers
    └── presentations/                # Stakeholder presentations
```

---

## Product Design Process

This project follows a standard 8-step product design process used in real product teams.

### Step 1 — Discovery Phase
**Who:** Product Manager + UX Researcher  
Field research — visit actual schools, talk to teachers, observe how students use phones. Output: user interview notes, pain points, competitive analysis.

### Step 2 — Define Phase
**Who:** Product Manager  
*(Current phase.)* Create the PRD (Product Requirements Document): vision, stakeholder map, user stories, and feature list with priorities.

### Step 3 — Design Phase
**Who:** UX Designer + UI Designer  
Three stages:
- **Wireframe** — rough black-and-white layout, no colours or fonts
- **Prototype** — clickable wireframe for user flow testing
- **High Fidelity Design** — final visuals with colours, fonts, animations

### Step 4 — Review Phase
**Who:** PM + Designer + Developers + Stakeholders  
Design review meeting. Developers confirm technical feasibility. PM verifies user story coverage. Edge cases (`05-edge-cases/`) are reviewed here.

### Step 5 — Design System
**Who:** UI Designer + Frontend Developer  
Define reusable design tokens and components:
- Colours (primary, secondary, error, success)
- Typography (headings, body, Gujarati font)
- Components (button, card, input, alert)
- Spacing (8px grid system)

### Step 6 — Handoff
**Who:** Designer to Developer  
Figma annotations with spacing, font sizes, colour hex codes. `requirements/` folder contains exact specs for developers.

### Step 7 — Development and Testing
**Who:** Developers + QA  
`09-testing/` folder — test cases, device testing (low-end Android), load testing for exam season spikes.

### Step 8 — Launch and Monitor
Deploy. Monitor on real users. Measure against success metrics defined in `01-vision/`.

---

## Document Types

| Document | Full Name | Purpose | Who Writes It |
|----------|-----------|---------|---------------|
| **PRD** | Product Requirements Document | User stories, features, vision — what to build and why | Product Manager |
| **BRD** | Business Requirements Document | Business-language requirements from the client (GMC) | Client / GMC |
| **FRD** | Functional Requirements Document | Exact feature behaviour, technical detail | Product + Dev team |
| **TRD** | Technical Requirements Document | Architecture, database, API design | Engineering team |

> The `docs/` folder in this project is essentially the **PRD**. The `requirements/` folder will contain the **FRD** and **TRD** once development planning begins.

---

## Constraints & Principles

Every design and engineering decision must respect these constraints.

### Device Constraints
- Low-end Android phones (2GB RAM, Android 8 or older)
- App size under **20MB** for initial install
- No assumption of camera or fast processor

### Connectivity Constraints
- Internet is unreliable — 2G, 3G, or none
- Core features must work **fully offline**
- Sync happens automatically when internet is available — no user action required

### User Constraints
- Many users are first-time digital tool users
- UI must be in **Gujarati** with simple icons
- No assumption of English literacy
- Onboarding must work without reading a manual

### Data and Legal Constraints
- All data is government data — subject to **India's DPDP Act 2023**
- No student data can leave **Indian servers**
- No third-party analytics or advertising SDKs
- No sensitive biometric data without explicit mandate

### Scale Constraints
- Must support **100+ schools** and **50,000+ students**
- Must handle **10x traffic spikes** during exam season

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Monthly active students (login at least once) | 80% of enrolled students |
| Teacher attendance upload within 24 hours | 95% of school days |
| Parent SMS delivery rate | 95%+ |
| App crash rate on low-end Android devices | Less than 1% |
| Average page load time on 3G connection | Under 3 seconds |
| Offline content availability when no internet | 100% of downloaded materials |
| Teacher satisfaction score (quarterly survey) | 4 out of 5 or higher |
| Support tickets per 100 users per month | Less than 2 |

---

## Roadmap

```
2026 Q2    Define Phase complete (PRD docs finalized)
2026 Q3    Design Phase (wireframes to high fidelity)
2026 Q4    Development begins + Alpha testing (internal)
2027 Q1    Pilot launch: 10 schools in Gandhinagar
2027 Q2    Review + iterate based on pilot feedback
2027 Q3    Scale to 50 schools, Gujarati language release
2028       100+ schools, 50,000+ students, AI early warning system
```

---

## Out of Scope

The following are explicitly **not** part of this product. Any request to add these must go through a formal change process.

- Paid courses or premium content tiers
- Third-party advertisements of any kind
- National board (CBSE/GSEB) direct integration (Phase 1)
- Video calling or live class features (Phase 1)
- Student-to-student messaging or social features
- Hardware procurement (tablets, devices for schools)
- Teacher payroll or HR management
- AI-generated content shown to students without teacher review

---

## Contributing

This is an internal GMC product documentation repository. If you are part of the product team:

1. All new documents go inside the `docs/` folder under the appropriate numbered section
2. Use `.mdx` format for all documentation files
3. Raise a PR with changes — PM approval required before merging
4. Any new feature that changes scope must reference a formal change request

---

**GMC Education Portal** — Built for Gandhinagar's government school students  
Version 1.0 · May 2026 · GMC Product Team
