import re

PATTERNS = {
    "list": re.compile(r"\b(listar|ver|mostrar).*(despesa|despesas|categoria)", re.I),
    "inc":  re.compile(r"\b(aumente|somar|acrescente|add|adicionar)\b.*\b([a-zçãéêíóôú ]+)\b.*\b(\d+[.,]?\d*)", re.I),
    "dec":  re.compile(r"\b(reduza|subtraia|remova|tirar)\b.*\b([a-zçãéêíóôú ]+)\b.*\b(\d+[.,]?\d*)", re.I),
    "set":  re.compile(r"\b(setar|definir|ajustar|colocar)\b.*\b([a-zçãéêíóôú ]+)\b.*\bpara\b.*\b(\d+[.,]?\d*)", re.I),
    "reset":re.compile(r"\b(zerar|apagar tudo|limpar tudo|resetar)\b", re.I),
}

def route(user_msg: str):
    m = PATTERNS["list"].search(user_msg)
    if m: return {"name":"db.get_expenses","args":{}}

    for key, sign in [("inc", +1), ("dec", -1)]:
        m = PATTERNS[key].search(user_msg)
        if m:
            cat = m.group(2).strip().title()
            val = float(m.group(3).replace(",","."))*sign
            return {"name":"db.update_expense","args":{"category":cat,"delta":val}}

    m = PATTERNS["set"].search(user_msg)
    if m:
        cat = m.group(2).strip().title()
        val = float(m.group(3).replace(",",".")) 
        return {"name":"db.set_category","args":{"category":cat,"total":val}}

    if PATTERNS["reset"].search(user_msg):
        return {"name":"db.reset","args":{}}

    return None
