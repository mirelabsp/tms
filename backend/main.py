from typing import Optional, List
import os
from datetime import datetime
from sqlmodel import Field, SQLModel, Session, create_engine, select
from fastapi import FastAPI, Depends, HTTPException

# --- CONFIGURAÇÃO DO BANCO DE DADOS ---
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/tmsdb")
engine = create_engine(DATABASE_URL, echo=True)


# --- MODELOS (ENTIDADES) ---

class Veiculo(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    placa: str
    modelo: Optional[str] = None
    capacidade: Optional[float] = None
    status: str = "ativo"

class Motorista(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nome: str
    cpf: str
    habilitacao: str
    status: str = "ativo"

class Rota(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    origem: str
    destino: str
    distancia_km: float
    status: str = "ativa"

class Entrega(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    descricao: str
    status: str = "pendente"  # Ex: pendente, em_transito, entregue, cancelada

    # Relacionamentos com outras tabelas
    veiculo_id: Optional[int] = Field(default=None, foreign_key="veiculo.id")
    motorista_id: Optional[int] = Field(default=None, foreign_key="motorista.id")
    rota_id: Optional[int] = Field(default=None, foreign_key="rota.id")


# --- FUNÇÕES CORE DA API ---

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

app = FastAPI(title="TMS API - Gestão de Transporte")

def get_session():
    with Session(engine) as session:
        yield session

@app.on_event("startup")
def on_startup():
    create_db_and_tables()


# --- ROTAS VEÍCULOS ---

@app.post("/veiculos/", response_model=Veiculo, tags=["Veículos"])
def criar_veiculo(veiculo: Veiculo, session: Session = Depends(get_session)):
    session.add(veiculo)
    session.commit()
    session.refresh(veiculo)
    return veiculo

@app.get("/veiculos/", response_model=List[Veiculo], tags=["Veículos"])
def listar_veiculos(session: Session = Depends(get_session)):
    return session.exec(select(Veiculo)).all()

@app.put("/veiculos/{veiculo_id}", response_model=Veiculo, tags=["Veículos"])
def atualizar_veiculo(veiculo_id: int, veiculo_atualizado: Veiculo, session: Session = Depends(get_session)):
    veiculo = session.get(Veiculo, veiculo_id)
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    
    veiculo_data = veiculo_atualizado.model_dump(exclude_unset=True)
    for key, value in veiculo_data.items():
        setattr(veiculo, key, value)

    session.add(veiculo)
    session.commit()
    session.refresh(veiculo)
    return veiculo

@app.delete("/veiculos/{veiculo_id}", tags=["Veículos"])
def deletar_veiculo(veiculo_id: int, session: Session = Depends(get_session)):
    veiculo = session.get(Veiculo, veiculo_id)
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    session.delete(veiculo)
    session.commit()
    return {"ok": True, "mensagem": f"Veículo {veiculo_id} removido com sucesso."}


# --- ROTAS MOTORISTAS ---

@app.post("/motoristas/", response_model=Motorista, tags=["Motoristas"])
def criar_motorista(motorista: Motorista, session: Session = Depends(get_session)):
    session.add(motorista)
    session.commit()
    session.refresh(motorista)
    return motorista

@app.get("/motoristas/", response_model=List[Motorista], tags=["Motoristas"])
def listar_motoristas(session: Session = Depends(get_session)):
    return session.exec(select(Motorista)).all()

@app.put("/motoristas/{motorista_id}", response_model=Motorista, tags=["Motoristas"])
def atualizar_motorista(motorista_id: int, motorista_atualizado: Motorista, session: Session = Depends(get_session)):
    motorista = session.get(Motorista, motorista_id)
    if not motorista:
        raise HTTPException(status_code=404, detail="Motorista não encontrado")
    
    motorista_data = motorista_atualizado.model_dump(exclude_unset=True)
    for key, value in motorista_data.items():
        setattr(motorista, key, value)
    
    session.add(motorista)
    session.commit()
    session.refresh(motorista)
    return motorista

@app.delete("/motoristas/{motorista_id}", tags=["Motoristas"])
def deletar_motorista(motorista_id: int, session: Session = Depends(get_session)):
    motorista = session.get(Motorista, motorista_id)
    if not motorista:
        raise HTTPException(status_code=404, detail="Motorista não encontrado")
    session.delete(motorista)
    session.commit()
    return {"ok": True, "mensagem": f"Motorista {motorista_id} removido com sucesso."}


# --- ROTAS ROTAS ---

@app.post("/rotas/", response_model=Rota, tags=["Rotas"])
def criar_rota(rota: Rota, session: Session = Depends(get_session)):
    session.add(rota)
    session.commit()
    session.refresh(rota)
    return rota

@app.get("/rotas/", response_model=List[Rota], tags=["Rotas"])
def listar_rotas(session: Session = Depends(get_session)):
    return session.exec(select(Rota)).all()

@app.put("/rotas/{rota_id}", response_model=Rota, tags=["Rotas"])
def atualizar_rota(rota_id: int, rota_atualizada: Rota, session: Session = Depends(get_session)):
    rota = session.get(Rota, rota_id)
    if not rota:
        raise HTTPException(status_code=404, detail="Rota não encontrada")
    
    rota_data = rota_atualizada.model_dump(exclude_unset=True)
    for key, value in rota_data.items():
        setattr(rota, key, value)
    
    session.add(rota)
    session.commit()
    session.refresh(rota)
    return rota

@app.delete("/rotas/{rota_id}", tags=["Rotas"])
def deletar_rota(rota_id: int, session: Session = Depends(get_session)):
    rota = session.get(Rota, rota_id)
    if not rota:
        raise HTTPException(status_code=404, detail="Rota não encontrada")
    session.delete(rota)
    session.commit()
    return {"ok": True, "mensagem": f"Rota {rota_id} removida com sucesso."}


# --- ROTAS ENTREGAS ---

@app.post("/entregas/", response_model=Entrega, tags=["Entregas"])
def criar_entrega(entrega: Entrega, session: Session = Depends(get_session)):
    session.add(entrega)
    session.commit()
    session.refresh(entrega)
    return entrega

@app.get("/entregas/", response_model=List[Entrega], tags=["Entregas"])
def listar_entregas(session: Session = Depends(get_session)):
    return session.exec(select(Entrega)).all()

@app.put("/entregas/{entrega_id}", response_model=Entrega, tags=["Entregas"])
def atualizar_entrega(entrega_id: int, entrega_atualizada: Entrega, session: Session = Depends(get_session)):
    entrega = session.get(Entrega, entrega_id)
    if not entrega:
        raise HTTPException(status_code=404, detail="Entrega não encontrada")
    
    entrega_data = entrega_atualizada.model_dump(exclude_unset=True)
    for key, value in entrega_data.items():
        setattr(entrega, key, value)
    
    session.add(entrega)
    session.commit()
    session.refresh(entrega)
    return entrega

@app.delete("/entregas/{entrega_id}", tags=["Entregas"])
def deletar_entrega(entrega_id: int, session: Session = Depends(get_session)):
    entrega = session.get(Entrega, entrega_id)
    if not entrega:
        raise HTTPException(status_code=404, detail="Entrega não encontrada")
    session.delete(entrega)
    session.commit()
    return {"ok": True, "mensagem": f"Entrega {entrega_id} removida com sucesso."}