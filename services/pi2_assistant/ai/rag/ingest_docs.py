# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\rag\ingest_docs.py
# REM (WHY): pipeline simples de ingestão de .txt/.md da família para RAG

import argparse, os, glob
from tqdm import tqdm
from .store import add_docs

def load_files(input_dir):
    docs, metas, ids = [], [], []
    for path in glob.glob(os.path.join(input_dir, "**", "*.*"), recursive=True):
        if path.lower().endswith((".txt",".md",".csv")):
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                text = f.read()
                if text.strip():
                    docs.append(text[:5000])  # corte simples
                    metas.append({"path": path})
                    ids.append(path.replace("\\","/"))
    return docs, metas, ids

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    args = ap.parse_args()
    docs, metas, ids = load_files(args.input)
    add_docs(docs, metas, ids)
    print(f"Ingeridos {len(ids)} documentos para RAG.")
