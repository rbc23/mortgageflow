# MortgageFlow

MortgageFlow is an Oracle APEX application designed to demonstrate a complete mortgage application and review workflow.

The project was created as a portfolio application to showcase end-to-end Oracle APEX development, including database design, PL/SQL business logic, authentication, role-based access, reporting, and application UI development.

## Main Features

MortgageFlow supports three user roles:

- **Applicant** – Explore loan products, calculate mortgage estimates, submit applications, and track application status.
- **Loan Officer** – Review submitted mortgage applications and approve or reject them.
- **Administrator** – Manage users, loan products, interest rates, audit logs, and application errors.

## Technologies

- Oracle APEX
- Oracle Database
- SQL
- PL/SQL
- ORDS / REST APIs
- HTML
- CSS
- JavaScript

## Main Application Flow

**Applicant**

Login → Dashboard → Loan Products → Mortgage Calculator → Submit Application → Track Application

**Loan Officer**

Login → Application Queue → Review Application → Start Review → Approve / Reject

**Administrator**

Login → Admin Dashboard → Manage Users, Products, Rates, Audit Logs, and Error Logs

## Database

The application includes tables for:

- Users
- Loan Products
- Interest Rates
- Mortgage Applications
- Application Status History
- Audit Logs
- Error Logs

Business logic is centralized in PL/SQL packages for authentication, mortgage calculations, application submission, and application processing.
