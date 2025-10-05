export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('en-CA', {
    style: 'currency',
    currency: 'CAD',
  }).format(amount);
};

export const formatDate = (dateString: string): string => {
  return new Date(dateString).toLocaleDateString('en-CA', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });
};

export const getCategoryIcon = (category: string): string => {
  const icons: Record<string, string> = {
    food: '🍽️',
    transport: '🚗',
    health: '💊',
    housing: '🏠',
    utilities: '⚡',
    shopping: '🛍️',
    entertainment: '🎬',
    education: '📚',
    savings: '💰',
    other: '📦',
  };
  return icons[category] || '📦';
};
