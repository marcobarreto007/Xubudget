"""
Xubudget Database Service
Gerencia persistência de despesas usando SQLite
"""

import sqlite3
import json
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Any
from pathlib import Path
import logging

logger = logging.getLogger(__name__)

class DatabaseService:
    def __init__(self, db_path: str = "xubudget.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Inicializa o banco de dados e cria as tabelas necessárias"""
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Criar tabela de despesas
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS expenses (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        description TEXT NOT NULL,
                        amount REAL NOT NULL,
                        category TEXT NOT NULL,
                        date TEXT NOT NULL,
                        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                # Criar índices para melhor performance
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_expenses_date 
                    ON expenses(date)
                ''')
                
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_expenses_category 
                    ON expenses(category)
                ''')
                
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_expenses_created_at 
                    ON expenses(created_at)
                ''')
                
                conn.commit()
                logger.info("Banco de dados inicializado com sucesso")
                
        except Exception as e:
            logger.error(f"Erro ao inicializar banco de dados: {e}")
            raise
    
    def add_expense(self, description: str, amount: float, category: str, date: str = None) -> Dict[str, Any]:
        """
        Adiciona uma nova despesa ao banco de dados
        
        Args:
            description: Descrição da despesa
            amount: Valor da despesa
            category: Categoria da despesa
            date: Data da despesa (formato YYYY-MM-DD), se None usa data atual
            
        Returns:
            Dict com os dados da despesa criada incluindo ID
        """
        try:
            if date is None:
                date = datetime.now().strftime("%Y-%m-%d")
            
            created_at = datetime.now().isoformat()
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute('''
                    INSERT INTO expenses (description, amount, category, date, created_at)
                    VALUES (?, ?, ?, ?, ?)
                ''', (description, amount, category, date, created_at))
                
                expense_id = cursor.lastrowid
                conn.commit()
                
                logger.info(f"Despesa adicionada: ID {expense_id}, {description}, R$ {amount}")
                
                return {
                    "id": expense_id,
                    "description": description,
                    "amount": amount,
                    "category": category,
                    "date": date,
                    "created_at": created_at
                }
                
        except Exception as e:
            logger.error(f"Erro ao adicionar despesa: {e}")
            raise
    
    def get_expenses(self, days: int = None, limit: int = None) -> List[Dict[str, Any]]:
        """
        Recupera despesas do banco de dados
        
        Args:
            days: Número de dias para filtrar (opcional)
            limit: Limite de registros (opcional)
            
        Returns:
            Lista de despesas
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                query = "SELECT * FROM expenses"
                params = []
                
                # Filtro por dias
                if days:
                    start_date = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")
                    query += " WHERE date >= ?"
                    params.append(start_date)
                
                # Ordenar por data mais recente
                query += " ORDER BY date DESC, created_at DESC"
                
                # Limite de registros
                if limit:
                    query += " LIMIT ?"
                    params.append(limit)
                
                cursor.execute(query, params)
                rows = cursor.fetchall()
                
                expenses = []
                for row in rows:
                    expenses.append({
                        "id": row["id"],
                        "description": row["description"],
                        "amount": row["amount"],
                        "category": row["category"],
                        "date": row["date"],
                        "created_at": row["created_at"]
                    })
                
                logger.info(f"Recuperadas {len(expenses)} despesas")
                return expenses
                
        except Exception as e:
            logger.error(f"Erro ao recuperar despesas: {e}")
            raise
    
    def get_by_category(self, category: str = None) -> List[Dict[str, Any]]:
        """
        Recupera despesas agrupadas por categoria
        
        Args:
            category: Categoria específica (opcional)
            
        Returns:
            Lista de despesas agrupadas por categoria
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                conn.row_factory = sqlite3.Row
                cursor = conn.cursor()
                
                if category:
                    query = "SELECT * FROM expenses WHERE category = ? ORDER BY date DESC"
                    cursor.execute(query, (category,))
                else:
                    query = "SELECT * FROM expenses ORDER BY category, date DESC"
                    cursor.execute(query)
                
                rows = cursor.fetchall()
                
                expenses = []
                for row in rows:
                    expenses.append({
                        "id": row["id"],
                        "description": row["description"],
                        "amount": row["amount"],
                        "category": row["category"],
                        "date": row["date"],
                        "created_at": row["created_at"]
                    })
                
                logger.info(f"Recuperadas {len(expenses)} despesas por categoria")
                return expenses
                
        except Exception as e:
            logger.error(f"Erro ao recuperar despesas por categoria: {e}")
            raise
    
    def get_category_summary(self) -> Dict[str, Any]:
        """
        Retorna resumo das despesas por categoria
        
        Returns:
            Dict com total por categoria e estatísticas
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                # Total por categoria
                cursor.execute('''
                    SELECT category, 
                           COUNT(*) as count, 
                           SUM(amount) as total,
                           AVG(amount) as average
                    FROM expenses 
                    GROUP BY category 
                    ORDER BY total DESC
                ''')
                
                category_data = []
                total_amount = 0
                
                for row in cursor.fetchall():
                    category_info = {
                        "category": row[0],
                        "count": row[1],
                        "total": round(row[2], 2),
                        "average": round(row[3], 2)
                    }
                    category_data.append(category_info)
                    total_amount += row[2]
                
                # Total geral
                cursor.execute('SELECT COUNT(*) FROM expenses')
                total_count = cursor.fetchone()[0]
                
                # Despesa mais recente
                cursor.execute('''
                    SELECT description, amount, date 
                    FROM expenses 
                    ORDER BY date DESC, created_at DESC 
                    LIMIT 1
                ''')
                recent = cursor.fetchone()
                
                summary = {
                    "categories": category_data,
                    "total_amount": round(total_amount, 2),
                    "total_count": total_count,
                    "recent_expense": {
                        "description": recent[0] if recent else None,
                        "amount": recent[1] if recent else None,
                        "date": recent[2] if recent else None
                    } if recent else None
                }
                
                logger.info(f"Resumo gerado: {total_count} despesas, R$ {total_amount:.2f}")
                return summary
                
        except Exception as e:
            logger.error(f"Erro ao gerar resumo: {e}")
            raise
    
    def delete_expense(self, expense_id: int) -> bool:
        """
        Remove uma despesa do banco de dados
        
        Args:
            expense_id: ID da despesa a ser removida
            
        Returns:
            True se removida com sucesso, False caso contrário
        """
        try:
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                cursor.execute("DELETE FROM expenses WHERE id = ?", (expense_id,))
                deleted = cursor.rowcount > 0
                conn.commit()
                
                if deleted:
                    logger.info(f"Despesa {expense_id} removida com sucesso")
                else:
                    logger.warning(f"Despesa {expense_id} não encontrada")
                
                return deleted
                
        except Exception as e:
            logger.error(f"Erro ao remover despesa: {e}")
            raise
    
    def update_expense(self, expense_id: int, **kwargs) -> bool:
        """
        Atualiza uma despesa existente
        
        Args:
            expense_id: ID da despesa
            **kwargs: Campos a serem atualizados
            
        Returns:
            True se atualizada com sucesso, False caso contrário
        """
        try:
            allowed_fields = ['description', 'amount', 'category', 'date']
            update_fields = {k: v for k, v in kwargs.items() if k in allowed_fields}
            
            if not update_fields:
                return False
            
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.cursor()
                
                set_clause = ", ".join([f"{field} = ?" for field in update_fields.keys()])
                values = list(update_fields.values()) + [expense_id]
                
                cursor.execute(f'''
                    UPDATE expenses 
                    SET {set_clause} 
                    WHERE id = ?
                ''', values)
                
                updated = cursor.rowcount > 0
                conn.commit()
                
                if updated:
                    logger.info(f"Despesa {expense_id} atualizada com sucesso")
                else:
                    logger.warning(f"Despesa {expense_id} não encontrada")
                
                return updated
                
        except Exception as e:
            logger.error(f"Erro ao atualizar despesa: {e}")
            raise

# Instância global do serviço de banco
db_service = DatabaseService()
