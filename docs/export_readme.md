# Export Documentation

## Overview
The Xubudget app provides comprehensive export functionality for your expense data, allowing you to backup and analyze your financial information using external tools.

## Export Formats

### CSV Export
- **Format**: Comma-separated values
- **Encoding**: UTF-8
- **Delimiter**: Comma (,)
- **Headers**: ID, Description, Amount, Category, Date, Source, Created At

### XLSX Export
- **Format**: Excel-compatible spreadsheet
- **Tab-separated**: Currently implemented as tab-separated text with .xlsx extension
- **Future**: Will be upgraded to native Excel format

## File Location

### Desktop (Windows)
Default export location: `%USERPROFILE%\Documents\Xubudget\data\exports\`
Example: `C:\Users\marco\Documents\Xubudget\data\exports\`

### Android
Default location: `/storage/emulated/0/Android/data/com.example.mobile_app/files/Documents/Xubudget/data/exports/`

### iOS
Default location: Application Documents directory under `Xubudget/data/exports/`

## File Naming Convention

All export files follow the timestamp pattern:
- **Pattern**: `expenses_YYYYMMDD_HHMMSS.{csv|xlsx}`
- **Examples**: 
  - `expenses_20240319_143022.csv`
  - `expenses_20240319_143022.xlsx`

## Timezone
All timestamps in exports use the device's local timezone.

## Usage

### Via Mobile App
1. Open the Xubudget app
2. Navigate to the Dashboard
3. Tap the download/export icon in the app bar
4. Choose your preferred format (CSV or XLSX)
5. Files are automatically saved to the exports directory
6. A success message confirms the export location

### Programmatic Usage
```dart
final exportService = ExportService();
final expenses = await expenseProvider.getAllExpenses();

// Export to CSV
final csvPath = await exportService.exportToCSV(expenses);
print('CSV exported to: $csvPath');

// Export to XLSX
final xlsxPath = await exportService.exportToXLSX(expenses);
print('XLSX exported to: $xlsxPath');
```

## Data Fields

Each exported record contains:

| Field | Description | Example |
|-------|-------------|---------|
| ID | Unique expense identifier | 1 |
| Description | Expense description | "Lunch at Restaurant XYZ" |
| Amount | Expense amount (decimal) | 25.50 |
| Category | Expense category | "alimentacao" |
| Date | Expense date (YYYY-MM-DD) | 2024-03-19 |
| Source | Data source method | "manual", "ocr", "voice" |
| Created At | Record creation timestamp | 2024-03-19 14:30:22 |

## Categories

Standard categories in exports:
- `alimentacao` - Food and dining
- `transporte` - Transportation
- `saude` - Health and medical
- `moradia` - Housing and utilities
- `lazer` - Entertainment and leisure
- `educacao` - Education
- `outros` - Other/miscellaneous

## Customizing Export Location

### Windows Desktop
To change the default export location, modify the documents directory path in your app settings or manually move files after export.

### Android
Files are exported to the app's document directory. You can find them using a file manager app or copy them to external storage.

## Troubleshooting

### Export Failed
- **Check storage permissions**: Ensure the app has write permissions
- **Verify available space**: Ensure sufficient storage space
- **Check file locks**: Close any open export files before creating new ones

### File Not Found
- **Check correct directory**: Navigate to the documented export path
- **Verify timestamp**: Files use the exact timestamp when created
- **Check app permissions**: Ensure file system access is granted

### Corrupted Export
- **Re-export data**: Try exporting again with latest data
- **Check file size**: Empty or very small files may indicate export errors
- **Verify data source**: Ensure expense data exists in the database

## Future Enhancements

- Native Excel (.xlsx) format support
- Custom export templates
- Filtered exports (by date range, category, etc.)
- Email export functionality
- Cloud storage integration
- Automated scheduled exports