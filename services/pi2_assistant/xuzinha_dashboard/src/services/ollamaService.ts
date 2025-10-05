// Ollama AI Service
const OLLAMA_BASE_URL = 'http://localhost:11434';

export interface OllamaResponse {
  response: string;
  done: boolean;
}

export interface CategorizeRequest {
  text: string;
}

export interface CategorizeResponse {
  category: string;
  confidence: number;
}

class OllamaService {
  private baseUrl: string;

  constructor(baseUrl: string = OLLAMA_BASE_URL) {
    this.baseUrl = baseUrl;
  }

  async isAvailable(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/api/tags`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      return response.ok;
    } catch (error) {
      console.error('Ollama not available:', error);
      return false;
    }
  }

  async categorizeExpense(text: string): Promise<CategorizeResponse> {
    try {
      const isAvailable = await this.isAvailable();
      if (!isAvailable) {
        throw new Error('Ollama is not available');
      }

      const prompt = `Categorize this Canadian expense into one of these categories: food, transport, health, housing, utilities, shopping, entertainment, education, savings, other.

Respond with only the category name, no explanations.

Text: ${text}

Category:`;

      const response = await fetch(`${this.baseUrl}/api/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'qwen2.5:1.5b-instruct',
          prompt: prompt,
          stream: false,
          options: {
            temperature: 0.1,
            top_p: 0.9,
            max_tokens: 50
          }
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.status}`);
      }

      const data: OllamaResponse = await response.json();
      const category = this.mapResponseToCategory(data.response.trim().toLowerCase());
      const confidence = this.calculateConfidence(data.response, text);

      return {
        category,
        confidence
      };
    } catch (error) {
      console.error('Error categorizing expense:', error);
      // Fallback categorization
      return this.fallbackCategorization(text);
    }
  }

  private mapResponseToCategory(response: string): string {
    const categoryMapping: { [key: string]: string[] } = {
      'food': ['food', 'alimentacao', 'comida', 'restaurante', 'mercado', 'supermercado', 'padaria', 'cafe', 'lanche'],
      'transport': ['transport', 'transporte', 'uber', 'taxi', 'combustivel', 'gasolina', 'onibus', 'metro', 'gas'],
      'health': ['health', 'saude', 'farmacia', 'hospital', 'medico', 'clinica', 'consulta', 'exame'],
      'housing': ['housing', 'moradia', 'casa', 'aluguel', 'apartamento', 'propriedade', 'imovel', 'rent'],
      'utilities': ['utilities', 'luz', 'agua', 'internet', 'energia', 'telefone', 'gas', 'bills'],
      'shopping': ['shopping', 'compras', 'loja', 'roupa', 'pessoal', 'mercadorias', 'clothes'],
      'entertainment': ['entertainment', 'lazer', 'cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'netflix', 'streaming'],
      'education': ['education', 'educacao', 'escola', 'universidade', 'curso', 'livro', 'estudo', 'course'],
      'savings': ['savings', 'poupanca', 'investimento', 'deposito', 'invest', 'emergency', 'fund'],
      'other': ['other', 'outros', 'diversos', 'miscelanea', 'misc']
    };

    for (const [category, keywords] of Object.entries(categoryMapping)) {
      if (keywords.some(keyword => response.includes(keyword))) {
        return category;
      }
    }

    return 'other';
  }

  private calculateConfidence(aiResponse: string, originalText: string): number {
    const validCategories = ['food', 'transport', 'health', 'housing', 'utilities', 'shopping', 'entertainment', 'education', 'savings', 'other'];
    
    if (validCategories.includes(aiResponse)) {
      return 0.95;
    } else if (validCategories.some(cat => aiResponse.includes(cat))) {
      return 0.85;
    } else {
      return 0.70;
    }
  }

  private fallbackCategorization(text: string): CategorizeResponse {
    const textLower = text.toLowerCase();
    
    const keywords: { [key: string]: string[] } = {
      'food': ['restaurante', 'mercado', 'super', 'padaria', 'lanche', 'comida', 'cafe', 'pizza', 'delivery', 'tim hortons', 'mcdonalds', 'loblaws'],
      'transport': ['uber', 'taxi', 'posto', 'combustivel', 'gasolina', 'onibus', 'metro', 'gas', 'shell', 'esso'],
      'health': ['farmacia', 'hospital', 'medico', 'clinica', 'consulta', 'exame', 'shoppers', 'pharmacy'],
      'housing': ['casa', 'aluguel', 'condominio', 'apartamento', 'propriedade', 'imovel', 'rent', 'landlord'],
      'utilities': ['luz', 'agua', 'gas', 'internet', 'telefone', 'energia', 'hydro', 'bell'],
      'shopping': ['compras', 'loja', 'shopping', 'roupa', 'pessoal', 'mercadorias', 'h&m', 'walmart'],
      'entertainment': ['cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'netflix', 'spotify', 'streaming'],
      'education': ['escola', 'universidade', 'curso', 'livro', 'material', 'estudo', 'udemy', 'coursera'],
      'savings': ['poupanca', 'investimento', 'deposito', 'invest', 'emergency', 'fund', 'bank', 'td']
    };

    for (const [category, words] of Object.entries(keywords)) {
      if (words.some(word => textLower.includes(word))) {
        return { category, confidence: 0.8 };
      }
    }

    return { category: 'other', confidence: 0.5 };
  }

  async chatWithXuzinha(message: string): Promise<string> {
    try {
      const isAvailable = await this.isAvailable();
      if (!isAvailable) {
        return "Sorry, I'm not available right now. Please try again later.";
      }

      const prompt = `You are Xuzinha, a friendly AI financial assistant for Canadian families. You help with personal finance management.

User message: ${message}

Respond as Xuzinha in a helpful, friendly way. Keep responses concise and practical.`;

      const response = await fetch(`${this.baseUrl}/api/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'qwen2.5:1.5b-instruct',
          prompt: prompt,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            max_tokens: 200
          }
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.status}`);
      }

      const data: OllamaResponse = await response.json();
      return data.response.trim();
    } catch (error) {
      console.error('Error chatting with Xuzinha:', error);
      return "I'm having trouble connecting right now. Please try again later!";
    }
  }

  async generateResponse(message: string, options: { model: string; context: string }): Promise<string> {
    try {
      const isAvailable = await this.isAvailable();
      if (!isAvailable) {
        throw new Error('Ollama is not available');
      }

      const prompt = `${options.context}

User message: ${message}

Respond as Xuzinha (be concise, helpful, and cyberpunk-themed):`;

      const response = await fetch(`${this.baseUrl}/api/generate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: options.model,
          prompt: prompt,
          stream: false,
          options: {
            temperature: 0.7,
            top_p: 0.9,
            max_tokens: 300
          }
        }),
      });

      if (!response.ok) {
        throw new Error(`Ollama API error: ${response.status}`);
      }

      const data: OllamaResponse = await response.json();
      return data.response.trim();
    } catch (error) {
      console.error('Error generating response:', error);
      throw error;
    }
  }
}

export const ollamaService = new OllamaService();
