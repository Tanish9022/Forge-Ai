Product Requirements Document (PRD)
Project Name: Story Nest
Project Category: Web-Based Story Publishing & Reading Platform
1. Purpose of the Document

This Product Requirements Document (PRD) defines the functional, technical, and operational requirements of the Story Nest system. It also enforces strict technology constraints to ensure standardization, simplicity, and academic compliance.

2. Product Overview

Story Nest is a web-based platform where users can read, write, and manage stories.
The system supports three user roles:

Reader

Author

Administrator

The platform enables story publishing, chapter management, reader interaction, analytics, and administrative moderation.

3. Target Users
User Type	Description
Reader	Reads stories, rates, comments, manages library
Author	Writes and publishes stories, views analytics
Admin	Manages users, moderates content, views reports
4. STRICT Technology Stack Rules
4.1 Frontend (STRICT & NON-NEGOTIABLE)

✅ Allowed

HTML5

CSS3

✅ UI Interaction Rule

All UI interaction must be implemented using CSS only

Cursor-based interaction allowed using:

:hover

:focus

:active

:checked

CSS transitions & animations

❌ Not Allowed

JavaScript (any kind)

JavaScript libraries or frameworks

React, Angular, Vue

jQuery

📌 Example

Dropdowns → CSS hover

Modals → checkbox + CSS

Animations → CSS transitions

Navigation → anchor links

4.2 Backend (STRICT)

✅ Allowed

Python only

Frameworks allowed:

Flask / Django / FastAPI (any one)

❌ Not Allowed

PHP

Java

Node.js

Any other backend language

📌 Backend Responsibilities

Authentication

Business logic

API handling

Role-based access control

4.3 Database (STRICT)

✅ Allowed

PostgreSQL

PL/pgSQL for:

Stored procedures

Triggers

Functions

❌ Not Allowed

MySQL

MongoDB

Firebase

ORM-only logic without PL/pgSQL

5. System Architecture
[ HTML + CSS Frontend ]
      (CSS cursor-based UI)
               ↓
        [ Python Backend ]
               ↓
[ PostgreSQL Database (PL/pgSQL) ]

6. Functional Requirements
6.1 User Authentication

Users can register and log in.

Role selection during registration.

Password hashing handled in Python backend.

6.2 Story Management (Author)

Create stories with title, genre, and tags.

Add chapters with content and sequence number.

Save stories as drafts.

Publish stories.

6.3 Reader Interaction

Browse and search stories.

Read chapters.

Rate stories (1–5 stars).

Comment on stories.

Save stories to personal library.

6.4 Admin Management

View total users and stories.

View reported content.

Approve or remove stories.

Block users if required.

6.5 Analytics

Track story views.

Calculate average ratings.

Count comments per story.

Display analytics to authors.

7. Non-Functional Requirements
7.1 Usability

Simple and minimal UI.

CSS-based animations for better UX.

Cursor-movement-based interactions.

7.2 Performance

Backend must handle concurrent requests.

Database queries must be optimized.

7.3 Security

Password hashing in Python.

SQL injection prevention.

Role-based access control.

7.4 Maintainability

Modular frontend structure.

Layered backend architecture.

Centralized database logic using PL/pgSQL.

8. Input Requirements
Author Inputs

Story title

Genre

Tags

Cover image

Chapter content

Reader Inputs

Search keywords

Ratings

Comments

Library actions

Admin Inputs

Moderation decisions

User management actions

9. Output Requirements

Story search results

Story reading pages

Author analytics dashboard

Reader library page

Admin reports

System notifications

10. Database Requirements (PL/pgSQL)

All business-critical logic must be implemented using PL/pgSQL.

Examples

Trigger to increase view count

Function to calculate average rating

Procedure to publish story

CREATE OR REPLACE FUNCTION calculate_avg_rating(storyid INT)
RETURNS NUMERIC AS $$
BEGIN
  RETURN (SELECT AVG(rating) FROM ratings WHERE story_id = storyid);
END;
$$ LANGUAGE plpgsql;

11. Constraints & Rules

Frontend must use only HTML and CSS

UI interaction must rely on cursor movement & CSS

Backend must be Python only

Database logic must use PL/pgSQL

No third-party CMS allowed

No JavaScript usage in frontend

12. Assumptions

Users have internet access.

System is web-based only.

Admins are trusted users.

13. Future Scope

Recommendation engine

Mobile-responsive enhancements

AI-based content suggestions

Accessibility improvements

14. Conclusion

Story Nest is designed as a modular, secure, and scalable web-based story platform. By enforcing strict separation of frontend, backend, and database technologies, the system ensures maintainability, performance, and academic compliance.