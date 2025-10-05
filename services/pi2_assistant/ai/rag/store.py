# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\rag\store.py
# REM (WHY): armazenamento vetorial local para buscar documentos familiares (RAG)

import chromadb
from chromadb.utils import embedding_functions

EMB_MODEL = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
CHROMA_DIR = "ai/rag/chroma_db"

def get_client():
    return chromadb.PersistentClient(path=CHROMA_DIR)

def collection():
    return get_client().get_or_create_collection(name="xuzinha_docs", embedding_function=EMB_MODEL)

def add_docs(docs, metadatas, ids):
    coll = collection()
    coll.add(documents=docs, metadatas=metadatas, ids=ids)

def search(query: str, k: int = 5):
    coll = collection()
    res = coll.query(query_texts=[query], n_results=k)
    out = []
    for i in range(len(res["ids"][0])):
        out.append({
            "id": res["ids"][0][i],
            "text": res["documents"][0][i],
            "meta": res["metadatas"][0][i]
        })
    return out
