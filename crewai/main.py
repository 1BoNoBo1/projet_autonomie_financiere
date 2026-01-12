"""
Application principale CrewAI pour l'autonomie financière
"""
import os
import logging
from typing import Optional
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

from crewai import Crew, Agent, Task

# Charger les variables d'environnement
load_dotenv()

# Configuration du logging
logging.basicConfig(
    level=os.getenv("CREWAI_LOG_LEVEL", "INFO"),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Initialiser FastAPI
app = FastAPI(
    title="CrewAI Autonomie Financière",
    description="API pour le cerveau IA d'autonomie financière",
    version="1.0.0"
)

# Configuration CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import des agents et outils
import sys
sys.path.insert(0, os.path.dirname(__file__))
from crewai.agents import (
    create_research_agent,
    create_analysis_agent,
    create_decision_agent
)
from crewai.tools import get_available_tools


class TaskRequest(BaseModel):
    """Modèle pour les requêtes de tâches"""
    task_type: str
    description: str
    context: Optional[dict] = None


class TaskResponse(BaseModel):
    """Modèle pour les réponses de tâches"""
    success: bool
    result: str
    agent_used: str
    execution_time: Optional[float] = None


@app.get("/")
async def root():
    """Endpoint racine"""
    return {
        "service": "CrewAI Autonomie Financière",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "crewai"
    }


@app.get("/agents")
async def list_agents():
    """Liste tous les agents disponibles"""
    return {
        "agents": [
            {
                "name": "research_agent",
                "role": "Recherche d'opportunités financières",
                "description": "Recherche et identifie les opportunités d'autonomie financière"
            },
            {
                "name": "analysis_agent",
                "role": "Analyse financière",
                "description": "Analyse les données et opportunités financières"
            },
            {
                "name": "decision_agent",
                "role": "Prise de décision",
                "description": "Prend des décisions basées sur l'analyse"
            }
        ]
    }


@app.get("/tools")
async def list_tools():
    """Liste tous les outils disponibles"""
    tools = get_available_tools()
    return {
        "tools": tools,
        "count": len(tools)
    }


@app.post("/execute", response_model=TaskResponse)
async def execute_task(request: TaskRequest):
    """Exécute une tâche avec l'agent approprié"""
    import time
    start_time = time.time()
    
    try:
        # Sélectionner l'agent approprié
        agent = None
        if request.task_type == "research":
            agent = create_research_agent()
        elif request.task_type == "analysis":
            agent = create_analysis_agent()
        elif request.task_type == "decision":
            agent = create_decision_agent()
        else:
            raise HTTPException(
                status_code=400,
                detail=f"Type de tâche inconnu: {request.task_type}"
            )
        
        # Créer la tâche
        task = Task(
            description=request.description,
            agent=agent,
            context=request.context or {}
        )
        
        # Créer le crew et exécuter
        crew = Crew(
            agents=[agent],
            tasks=[task],
            verbose=True
        )
        
        result = crew.kickoff()
        execution_time = time.time() - start_time
        
        return TaskResponse(
            success=True,
            result=str(result),
            agent_used=request.task_type,
            execution_time=execution_time
        )
        
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution de la tâche: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de l'exécution: {str(e)}"
        )


@app.post("/crew/execute")
async def execute_crew_task(request: TaskRequest):
    """Exécute une tâche avec un crew complet (tous les agents)"""
    import time
    start_time = time.time()
    
    try:
        # Créer tous les agents
        research_agent = create_research_agent()
        analysis_agent = create_analysis_agent()
        decision_agent = create_decision_agent()
        
        # Créer les tâches en séquence
        research_task = Task(
            description=f"Recherche: {request.description}",
            agent=research_agent
        )
        
        analysis_task = Task(
            description=f"Analyse les résultats de la recherche",
            agent=analysis_agent,
            context={"previous_task": research_task}
        )
        
        decision_task = Task(
            description=f"Prendre une décision basée sur l'analyse",
            agent=decision_agent,
            context={"previous_task": analysis_task}
        )
        
        # Créer le crew
        crew = Crew(
            agents=[research_agent, analysis_agent, decision_agent],
            tasks=[research_task, analysis_task, decision_task],
            verbose=True
        )
        
        result = crew.kickoff()
        execution_time = time.time() - start_time
        
        return {
            "success": True,
            "result": str(result),
            "execution_time": execution_time
        }
        
    except Exception as e:
        logger.error(f"Erreur lors de l'exécution du crew: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur lors de l'exécution: {str(e)}"
        )


if __name__ == "__main__":
    port = int(os.getenv("CREWAI_PORT", 8000))
    host = os.getenv("CREWAI_HOST", "0.0.0.0")
    
    uvicorn.run(
        "main:app",
        host=host,
        port=port,
        reload=os.getenv("CREWAI_RELOAD", "false").lower() == "true"
    )
