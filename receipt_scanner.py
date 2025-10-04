"""
Receipt Scanner Module
Handles OCR and receipt processing for Xubudget
"""

import re
import json
from typing import Dict, List, Optional, Tuple
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ReceiptScanner:
    """Handles receipt scanning and data extraction"""
    
    def __init__(self):
        self.currency_patterns = [
            r'\$\s*(\d+\.?\d*)',  # $25.50
            r'(\d+\.?\d*)\s*\$',  # 25.50$
            r'CAD\s*(\d+\.?\d*)', # CAD 25.50
            r'(\d+\.?\d*)\s*CAD', # 25.50 CAD
            r'Total:\s*\$?(\d+\.?\d*)',  # Total: $25.50
            r'Amount:\s*\$?(\d+\.?\d*)', # Amount: $25.50
        ]
        
        self.date_patterns = [
            r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})',  # MM/DD/YYYY or DD/MM/YYYY
            r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})',  # YYYY/MM/DD
            r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{2,4})',  # DD Mon YYYY
        ]
        
        self.month_names = {
            'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
            'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
        }
        
        self.merchant_keywords = [
            'store', 'market', 'grocery', 'restaurant', 'cafe', 'shop',
            'pharmacy', 'gas', 'station', 'mall', 'center', 'mart'
        ]

    def extract_amount(self, text: str) -> Optional[float]:
        """Extract monetary amount from text"""
        try:
            for pattern in self.currency_patterns:
                matches = re.findall(pattern, text, re.IGNORECASE)
                if matches:
                    # Get the largest amount found
                    amounts = []
                    for match in matches:
                        try:
                            amount = float(match)
                            amounts.append(amount)
                        except ValueError:
                            continue
                    
                    if amounts:
                        return max(amounts)
            
            # Fallback: look for any number that could be an amount
            numbers = re.findall(r'\d+\.?\d*', text)
            if numbers:
                # Filter reasonable amounts (between 0.01 and 10000)
                valid_amounts = [float(n) for n in numbers if 0.01 <= float(n) <= 10000]
                if valid_amounts:
                    return max(valid_amounts)
            
            return None
        except Exception as e:
            logger.error(f"Error extracting amount: {e}")
            return None

    def extract_date(self, text: str) -> Optional[str]:
        """Extract date from text"""
        try:
            for pattern in self.date_patterns:
                matches = re.findall(pattern, text, re.IGNORECASE)
                if matches:
                    for match in matches:
                        try:
                            if len(match) == 3:
                                if len(match[2]) == 4:  # Full year
                                    year = int(match[2])
                                else:  # 2-digit year
                                    year = 2000 + int(match[2])
                                
                                if match[1].lower() in self.month_names:  # Month name
                                    month = self.month_names[match[1].lower()]
                                    day = int(match[0])
                                else:  # Numeric month
                                    month = int(match[1])
                                    day = int(match[0])
                                
                                # Validate date
                                if 1 <= month <= 12 and 1 <= day <= 31:
                                    return f"{year}-{month:02d}-{day:02d}"
                        except (ValueError, IndexError):
                            continue
            
            return None
        except Exception as e:
            logger.error(f"Error extracting date: {e}")
            return None

    def extract_merchant(self, text: str) -> Optional[str]:
        """Extract merchant name from text"""
        try:
            lines = text.split('\n')
            
            # Look for lines that might contain merchant name
            for line in lines[:10]:  # Check first 10 lines
                line = line.strip()
                if len(line) > 3 and len(line) < 50:  # Reasonable length
                    # Check if line contains merchant keywords
                    if any(keyword in line.lower() for keyword in self.merchant_keywords):
                        return line
                    
                    # Check if line looks like a business name (no numbers, proper case)
                    if re.match(r'^[A-Za-z\s&]+$', line) and not re.search(r'\d', line):
                        return line
            
            # Fallback: return first non-empty line
            for line in lines:
                line = line.strip()
                if len(line) > 3:
                    return line
            
            return None
        except Exception as e:
            logger.error(f"Error extracting merchant: {e}")
            return None

    def categorize_receipt(self, text: str, merchant: str = None) -> str:
        """Categorize receipt based on content and merchant"""
        try:
            text_lower = text.lower()
            merchant_lower = (merchant or "").lower()
            
            # Food-related keywords
            food_keywords = [
                'grocery', 'supermarket', 'food', 'restaurant', 'cafe', 'deli',
                'bakery', 'meat', 'produce', 'dairy', 'bread', 'milk', 'eggs',
                'chicken', 'beef', 'pork', 'fish', 'vegetables', 'fruits'
            ]
            
            # Transport keywords
            transport_keywords = [
                'gas', 'fuel', 'gasoline', 'station', 'parking', 'metro',
                'bus', 'taxi', 'uber', 'lyft', 'toll', 'highway'
            ]
            
            # Health keywords
            health_keywords = [
                'pharmacy', 'drug', 'medicine', 'clinic', 'hospital',
                'doctor', 'medical', 'prescription', 'vitamin', 'health'
            ]
            
            # Housing keywords
            housing_keywords = [
                'rent', 'mortgage', 'utilities', 'electric', 'water',
                'internet', 'cable', 'insurance', 'maintenance'
            ]
            
            # Leisure keywords
            leisure_keywords = [
                'movie', 'cinema', 'theater', 'game', 'entertainment',
                'sports', 'gym', 'fitness', 'music', 'book', 'magazine'
            ]
            
            # Education keywords
            education_keywords = [
                'school', 'university', 'college', 'course', 'book',
                'education', 'tuition', 'student', 'learning'
            ]
            
            # Check merchant first
            if merchant_lower:
                for keyword in food_keywords:
                    if keyword in merchant_lower:
                        return 'food'
                for keyword in transport_keywords:
                    if keyword in merchant_lower:
                        return 'transport'
                for keyword in health_keywords:
                    if keyword in merchant_lower:
                        return 'health'
                for keyword in housing_keywords:
                    if keyword in merchant_lower:
                        return 'housing'
                for keyword in leisure_keywords:
                    if keyword in merchant_lower:
                        return 'leisure'
                for keyword in education_keywords:
                    if keyword in merchant_lower:
                        return 'education'
            
            # Check text content
            for keyword in food_keywords:
                if keyword in text_lower:
                    return 'food'
            for keyword in transport_keywords:
                if keyword in text_lower:
                    return 'transport'
            for keyword in health_keywords:
                if keyword in text_lower:
                    return 'health'
            for keyword in housing_keywords:
                if keyword in text_lower:
                    return 'housing'
            for keyword in leisure_keywords:
                if keyword in text_lower:
                    return 'leisure'
            for keyword in education_keywords:
                if keyword in text_lower:
                    return 'education'
            
            return 'other'
        except Exception as e:
            logger.error(f"Error categorizing receipt: {e}")
            return 'other'

    def scan_receipt(self, text: str) -> Dict:
        """Main function to scan and extract data from receipt text"""
        try:
            logger.info("Starting receipt scan...")
            
            # Extract data
            amount = self.extract_amount(text)
            date = self.extract_date(text)
            merchant = self.extract_merchant(text)
            category = self.categorize_receipt(text, merchant)
            
            # Create description
            description = f"Receipt from {merchant}" if merchant else "Receipt"
            if amount:
                description += f" - ${amount:.2f}"
            
            result = {
                'success': True,
                'data': {
                    'description': description,
                    'amount': amount,
                    'date': date or datetime.now().strftime('%Y-%m-%d'),
                    'category': category,
                    'merchant': merchant,
                    'raw_text': text[:500]  # First 500 chars for reference
                },
                'confidence': self._calculate_confidence(amount, date, merchant)
            }
            
            logger.info(f"Receipt scan completed: {result['data']['description']}")
            return result
            
        except Exception as e:
            logger.error(f"Error scanning receipt: {e}")
            return {
                'success': False,
                'error': str(e),
                'data': None
            }

    def _calculate_confidence(self, amount: float, date: str, merchant: str) -> float:
        """Calculate confidence score for extracted data"""
        confidence = 0.0
        
        if amount:
            confidence += 0.4
        if date:
            confidence += 0.3
        if merchant:
            confidence += 0.3
            
        return min(confidence, 1.0)

# Test function
def test_receipt_scanner():
    """Test the receipt scanner with sample data"""
    scanner = ReceiptScanner()
    
    # Sample receipt text
    sample_receipt = """
    WALMART SUPERCENTER
    123 Main Street
    Toronto, ON M1A 1A1
    
    Receipt #12345
    Date: 2024-10-04
    Cashier: John Doe
    
    Items:
    - Milk 2L          $4.99
    - Bread Whole Wheat $2.49
    - Apples 2lbs      $3.99
    - Chicken Breast   $12.99
    
    Subtotal:         $24.46
    Tax (13%):        $3.18
    Total:            $27.64
    
    Thank you for shopping!
    """
    
    result = scanner.scan_receipt(sample_receipt)
    print("Receipt Scan Test:")
    print(json.dumps(result, indent=2))
    
    return result

if __name__ == "__main__":
    test_receipt_scanner()
