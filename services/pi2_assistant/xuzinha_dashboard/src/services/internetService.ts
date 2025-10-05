// Internet Search Service for Xuzinha
export interface SearchResult {
  title: string;
  snippet: string;
  url: string;
  source: string;
}

export interface InternetResponse {
  success: boolean;
  results: SearchResult[];
  query: string;
  timestamp: Date;
}

class InternetService {
  private readonly DUCKDUCKGO_API = 'https://api.duckduckgo.com/';
  private readonly SEARCH_ENGINE = 'duckduckgo';

  async searchWeb(query: string, maxResults: number = 5): Promise<InternetResponse> {
    try {
      console.log('InternetService: Searching for:', query);
      
      // For now, we'll use a mock service since DuckDuckGo API requires special setup
      // In production, you'd use a real search API like Google Custom Search, Bing, or DuckDuckGo
      const mockResults = await this.getMockSearchResults(query, maxResults);
      
      return {
        success: true,
        results: mockResults,
        query: query,
        timestamp: new Date()
      };
    } catch (error) {
      console.error('InternetService: Search error:', error);
      return {
        success: false,
        results: [],
        query: query,
        timestamp: new Date()
      };
    }
  }

  private async getMockSearchResults(query: string, maxResults: number): Promise<SearchResult[]> {
    // Mock search results based on query
    const mockResults: SearchResult[] = [];
    
    const lowerQuery = query.toLowerCase();
    
    if (lowerQuery.includes('budget') || lowerQuery.includes('orçamento') || lowerQuery.includes('finanças')) {
      mockResults.push({
        title: "Personal Budgeting Tips - Financial Planning Guide",
        snippet: "Learn how to create and maintain a personal budget. Track your income and expenses, set financial goals, and save money effectively.",
        url: "https://example.com/budgeting-tips",
        source: "Financial Planning Institute"
      });
      mockResults.push({
        title: "50/30/20 Budget Rule - Simple Budgeting Method",
        snippet: "The 50/30/20 rule suggests spending 50% on needs, 30% on wants, and 20% on savings. A simple and effective budgeting strategy.",
        url: "https://example.com/50-30-20-rule",
        source: "Personal Finance Blog"
      });
    }
    
    if (lowerQuery.includes('investment') || lowerQuery.includes('investimento') || lowerQuery.includes('poupança')) {
      mockResults.push({
        title: "Beginner's Guide to Investing - Start Building Wealth",
        snippet: "Learn the basics of investing, from stocks and bonds to mutual funds and ETFs. Start your investment journey today.",
        url: "https://example.com/investing-guide",
        source: "Investment Academy"
      });
      mockResults.push({
        title: "Emergency Fund: How Much Should You Save?",
        snippet: "Financial experts recommend saving 3-6 months of expenses in an emergency fund. Learn how to build yours step by step.",
        url: "https://example.com/emergency-fund",
        source: "Financial Security Institute"
      });
    }
    
    if (lowerQuery.includes('debt') || lowerQuery.includes('dívida') || lowerQuery.includes('cartão')) {
      mockResults.push({
        title: "Debt Management Strategies - Get Out of Debt Faster",
        snippet: "Learn effective strategies to pay off debt, including the debt snowball and debt avalanche methods.",
        url: "https://example.com/debt-management",
        source: "Debt Relief Center"
      });
    }
    
    if (lowerQuery.includes('tax') || lowerQuery.includes('imposto') || lowerQuery.includes('fiscal')) {
      mockResults.push({
        title: "Tax Planning Tips for Canadians - Maximize Your Returns",
        snippet: "Learn about Canadian tax deductions, credits, and strategies to minimize your tax burden legally.",
        url: "https://example.com/canadian-tax-tips",
        source: "Canadian Tax Institute"
      });
    }
    
    if (lowerQuery.includes('retirement') || lowerQuery.includes('aposentadoria') || lowerQuery.includes('pensão')) {
      mockResults.push({
        title: "Retirement Planning in Canada - RRSP and TFSA Guide",
        snippet: "Learn about Canadian retirement savings options including RRSP, TFSA, and CPP. Plan for a secure retirement.",
        url: "https://example.com/canadian-retirement",
        source: "Retirement Planning Canada"
      });
    }
    
    // Default financial advice if no specific topic matches
    if (mockResults.length === 0) {
      mockResults.push({
        title: "Personal Finance Basics - Financial Literacy Guide",
        snippet: "Learn the fundamentals of personal finance including budgeting, saving, investing, and debt management.",
        url: "https://example.com/personal-finance-basics",
        source: "Financial Education Center"
      });
      mockResults.push({
        title: "Money Management Tips - Control Your Finances",
        snippet: "Practical tips for managing your money, tracking expenses, and building wealth over time.",
        url: "https://example.com/money-management",
        source: "Money Management Institute"
      });
    }
    
    return mockResults.slice(0, maxResults);
  }

  async searchFinancialNews(query: string): Promise<InternetResponse> {
    try {
      console.log('InternetService: Searching financial news for:', query);
      
      const mockResults: SearchResult[] = [
        {
          title: "Latest Financial News - Market Updates",
          snippet: "Stay updated with the latest financial news, market trends, and economic indicators affecting your investments.",
          url: "https://example.com/financial-news",
          source: "Financial Times"
        },
        {
          title: "Economic Outlook 2024 - What to Expect",
          snippet: "Expert analysis of economic trends and predictions for the coming year. Plan your finances accordingly.",
          url: "https://example.com/economic-outlook",
          source: "Economic Research Institute"
        }
      ];
      
      return {
        success: true,
        results: mockResults,
        query: query,
        timestamp: new Date()
      };
    } catch (error) {
      console.error('InternetService: Financial news search error:', error);
      return {
        success: false,
        results: [],
        query: query,
        timestamp: new Date()
      };
    }
  }

  async searchCanadianFinance(query: string): Promise<InternetResponse> {
    try {
      console.log('InternetService: Searching Canadian finance for:', query);
      
      const mockResults: SearchResult[] = [
        {
          title: "Canadian Financial Services - Banking and Credit",
          snippet: "Information about Canadian banks, credit unions, and financial services available to residents.",
          url: "https://example.com/canadian-banking",
          source: "Canadian Banking Association"
        },
        {
          title: "Government Benefits and Assistance Programs",
          snippet: "Learn about Canadian government benefits, tax credits, and financial assistance programs available to you.",
          url: "https://example.com/canadian-benefits",
          source: "Government of Canada"
        }
      ];
      
      return {
        success: true,
        results: mockResults,
        query: query,
        timestamp: new Date()
      };
    } catch (error) {
      console.error('InternetService: Canadian finance search error:', error);
      return {
        success: false,
        results: [],
        query: query,
        timestamp: new Date()
      };
    }
  }
}

export const internetService = new InternetService();
