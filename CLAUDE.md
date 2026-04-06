# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BHSS Insider is a Flutter-based admin portal for Black Hawk Security Solution - a security services company. The app manages employees, invoices, events, and job vacancies. It includes PDF invoice generation with GST calculations and company branding.

## Development Commands

### Essential Commands
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific device
flutter run -d <device-id>

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Analyze code for issues
flutter analyze

# Analyze specific files/directories
flutter analyze lib/screens/
flutter analyze lib/services/database_service.dart

# Run tests
flutter test
```

## Architecture

### Database Layer (SQLite)
- **Service**: `lib/services/database_service.dart` - Singleton pattern managing all database operations
- **Tables**: employees, invoices, invoice_items, events, vacancies
- All CRUD operations go through DatabaseService methods
- Invoice items have foreign key relationship with invoices (ON DELETE CASCADE)
- Invoice number generation: `01/2025-26` format (serial/financial-year, resets each FY April-March)

### Models
- **Employee** (`lib/models/employee.dart`) - Employee management with salary, position, active status
- **Invoice** (`lib/models/invoice.dart`) - Invoice with items, tax calculations (CGST/SGST), round-off logic
  - Important: `grandTotal` rounds to nearest integer, `roundOff` shows adjustment amount
  - Invoice items calculate amount as `quantity * rate`
- **Event** (`lib/models/event.dart`) - Company events with date, location
- **Vacancy** (`lib/models/vacancy.dart`) - Job postings with openings count, optional salary range

### PDF Generation
- **Service**: `lib/services/pdf_service.dart`
- Uses `pdf` and `printing` packages with Noto Sans fonts (supports rupee symbol)
- Invoice PDF structure: Company header → Invoice details → Items table → Totals/Terms → Bank details/Signature
- Number to words conversion supports Indian numbering system (Lakh, Crore)
- PDFs saved to: `<external_storage>/BHSS_Invoices/` or app documents directory
- Payment terms: 05 days from invoice date

### UI Structure
- **Bottom Navigation**: 3 tabs - Home, Employees, Invoices
- **Home Screen** (`lib/screens/home_screen.dart`): Displays upcoming events and active vacancies
- **Employees Section** (`lib/screens/employees/`): List view with add/edit/delete functionality
- **Invoices Section** (`lib/screens/invoices/`): Invoice list, form for creating invoices with multiple items, PDF generation

### Authentication
- Simple SharedPreferences-based login (no backend)
- Credentials in `lib/utils/constants.dart`: username=admin, password=admin
- Splash screen checks login status and routes accordingly

### Theme & Styling
- **Colors**: `lib/utils/colors.dart` - Primary blue (#1E3A8A), secondary gold (#F59E0B), accent yellow
- **Text Styles**: `lib/utils/text_styles.dart` - Consistent typography throughout app
- Material 3 design with rounded corners (12px radius for buttons/cards)

### Company Constants
All company details centralized in `lib/utils/constants.dart`:
- Company name, address, contact details
- Bank account information for invoices
- GST/PAN numbers
- Default tax rates (9% CGST + 9% SGST = 18% total)

## Key Implementation Details

### Invoice Calculations
The Invoice model computes totals in this sequence:
1. `subtotal` = sum of all item amounts
2. `cgstAmount` = subtotal * 9%
3. `sgstAmount` = subtotal * 9%
4. `totalBeforeRounding` = subtotal + CGST + SGST
5. `grandTotal` = rounded total (nearest integer)
6. `roundOff` = grandTotal - totalBeforeRounding (can be negative)

### PDF Invoice Layout
Fixed structure with bordered tables:
- Header: Company name, address, contacts, GSTIN (grey background)
- Invoice metadata: Number, date, SAC, place of supply
- Items table: Serial, Particulars, Quantity, Rate, Amount
- Totals section includes: Subtotal, CGST, SGST, Round Off (with +/- sign), Grand Total
- Terms & Conditions: 3 payment terms listed
- Footer: Bank details (left) and authorized signature space (right)

### Database Updates
When updating invoices:
1. Update invoice record
2. Delete all old invoice_items for that invoice
3. Insert new invoice_items
This ensures item list stays in sync with invoice

## Development Notes

- Uses Dart 3.9.2 SDK
- Target platforms: Android, iOS, Web
- No backend - all data stored locally in SQLite
- Login is not secure - meant for single admin use on trusted device
- Invoice PDFs use external storage permission on Android
