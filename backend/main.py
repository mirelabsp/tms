from typing import Optional, List
import os
from sqlmodel import Field, SQLModel, Session, create_engine, select
from fastapi import FastAPI, Depends, HTTPException

# URL do banco (usando variável de ambiente ou padrão local)
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@db:5432/tmsdb")
engine = create_engine(DATABASE_URL, echo=True)

# MODELO VEÍCULO
class Veiculo(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    placa: str
    modelo: Optional[str] = None
    capacidade: Optional[float] = None
    status: str = "ativo"

# Criar tabelas no banco
def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

# Instancia o app
app = FastAPI(title="TMS API")

# Conexão com o banco
def get_session():
    with Session(engine) as session:
        yield session

# Evento que roda ao iniciar a API
@app.on_event("startup")
def on_startup():
    create_db_and_tables()

# ROTA: Criar veículo
@app.post("/veiculos/", response_model=Veiculo)
def criar_veiculo(veiculo: Veiculo, session: Session = Depends(get_session)):
    session.add(veiculo)
    session.commit()
    session.refresh(veiculo)
    return veiculo

# ROTA: Listar veículos
@app.get("/veiculos/", response_model=List[Veiculo])
def listar_veiculos(session: Session = Depends(get_session)):
    return session.exec(select(Veiculo)).all()

# ROTA: Atualizar veículo
@app.put("/veiculos/{veiculo_id}", response_model=Veiculo)
def atualizar_veiculo(veiculo_id: int, veiculo_atualizado: Veiculo, session: Session = Depends(get_session)):
    veiculo = session.get(Veiculo, veiculo_id)
    if not veiculo:
        raise HTTPException(status_code=404, detail="Veículo não encontrado")
    
    veiculo.placa = veiculo_atualizado.placa
    veiculo.modelo = veiculo_atualizado.modelo
    veiculo.capacidade = veiculo_atualizado.capacidade
    veiculo.status = veiculo_atualizado.status

    session.add(veiculo)
    session.commit()
    session.refresh(veiculo)
    return veiculo
